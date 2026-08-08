--!strict

-- Echo Git Sync
-- Roblox Studio -> GitHub source sync plugin
-- Default repository: https://github.com/EchoStorms/The-Obby

assert(plugin, "Echo Git Sync must run as a Roblox Studio plugin")

local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local ScriptEditorService = game:GetService("ScriptEditorService")

----------------------------------------------------------------
-- TYPES
----------------------------------------------------------------

type HttpResponse = {
	Success: boolean,
	StatusCode: number,
	StatusMessage: string,
	Headers: {[string]: string},
	Body: string,
}

type Config = {
	Owner: string,
	Repo: string,
	Branch: string,
	Root: string,
}

type SourceEntry = {
	Path: string,
	Content: string,
	Source: LuaSourceContainer,
}

type HeadState = {
	CommitSha: string,
	TreeSha: string,
}

type SelectionMode = "Sync" | "Create"

----------------------------------------------------------------
-- CONSTANTS / SAVED SETTINGS
----------------------------------------------------------------

local API_VERSION = "2026-03-10"
local API_ORIGIN = "https://api.github.com"
local MAX_HTTP_ATTEMPTS = 3

local KEY_OWNER = "EchoGitSync.Owner.v1"
local KEY_REPO = "EchoGitSync.Repo.v1"
local KEY_BRANCH = "EchoGitSync.Branch.v1"
local KEY_ROOT = "EchoGitSync.Root.v1"
local KEY_TOKEN = "EchoGitSync.Token.v1"

-- Used only when two or more Studio scripts would otherwise map to the same
-- repository path (Roblox allows siblings with identical names).
-- This attribute is written onto the Script/LocalScript/ModuleScript so the
-- generated GitHub path stays stable across Studio sessions.
local COLLISION_ID_ATTRIBUTE = "EchoGitSyncId"
local COLLISION_ID_PATH_LENGTH = 12

local DEFAULT_CONFIG: Config = {
	Owner = "EchoStorms",
	Repo = "The-Obby",
	Branch = "main",
	Root = "src",
}

local function trim(value: string): string
	return value:match("^%s*(.-)%s*$") or value
end

local function loadStringSetting(key: string, defaultValue: string, allowEmpty: boolean?): string
	local value = plugin:GetSetting(key)
	if typeof(value) == "string" then
		local stringValue = trim(value)
		if allowEmpty or stringValue ~= "" then
			return stringValue
		end
	end
	return defaultValue
end

local config: Config = {
	Owner = loadStringSetting(KEY_OWNER, DEFAULT_CONFIG.Owner),
	Repo = loadStringSetting(KEY_REPO, DEFAULT_CONFIG.Repo),
	Branch = loadStringSetting(KEY_BRANCH, DEFAULT_CONFIG.Branch),
	Root = loadStringSetting(KEY_ROOT, DEFAULT_CONFIG.Root, true),
}

local token = loadStringSetting(KEY_TOKEN, "", true)

----------------------------------------------------------------
-- STATUS
----------------------------------------------------------------

local statusLabel: TextLabel? = nil

local function setStatus(message: string, isError: boolean?)
	if statusLabel then
		statusLabel.Text = message
	end

	if isError then
		warn("[Echo Git Sync] " .. message)
	else
		print("[Echo Git Sync] " .. message)
	end
end

----------------------------------------------------------------
-- CONFIG VALIDATION
----------------------------------------------------------------

local function validateSimpleName(value: string, fieldName: string)
	assert(value ~= "", fieldName .. " cannot be empty")
	assert(not value:find("%s"), fieldName .. " cannot contain whitespace")
end

local function validateRepoRelativePath(path: string, allowEmpty: boolean?)
	if allowEmpty and path == "" then
		return
	end

	assert(path ~= "", "Repository path cannot be empty")
	assert(path:sub(1, 1) ~= "/", "Repository paths must be relative, not absolute")
	assert(not path:find("\\", 1, true), "Use / instead of \\ in repository paths")

	for _, segment in ipairs(string.split(path, "/")) do
		assert(segment ~= "", "Repository path cannot contain empty segments")
		assert(segment ~= ".", "Repository path cannot contain . segments")
		assert(segment ~= "..", "Repository path cannot contain .. segments")
	end
end

local function validateConfig()
	config.Owner = trim(config.Owner)
	config.Repo = trim(config.Repo)
	config.Branch = trim(config.Branch)
	config.Root = trim(config.Root)

	validateSimpleName(config.Owner, "Owner")
	validateSimpleName(config.Repo, "Repository")
	assert(config.Branch ~= "", "Branch cannot be empty")
	validateRepoRelativePath(config.Root, true)
	assert(token ~= "", "No GitHub token is saved. Open Settings and save a fine-grained token first.")
end

----------------------------------------------------------------
-- SOURCE / PATH MAPPING
----------------------------------------------------------------

local function isSourceContainer(instance: Instance): boolean
	return instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript")
end

local EXCLUDED_TOP_LEVEL: {[string]: boolean} = {
	PluginDebugService = true,
	CoreGui = true,
	CorePackages = true,
}

local function topLevelAncestor(instance: Instance): Instance
	local current = instance
	while current.Parent and current.Parent ~= game do
		current = current.Parent
	end
	return current
end

local function isSyncEligible(source: LuaSourceContainer): boolean
	-- Opt-out for project scripts you intentionally do not want in GitHub.
	if source:GetAttribute("GitHubSyncIgnore") == true then
		return false
	end

	-- Local plugins live under PluginDebugService while being developed.
	-- Core/system containers are not part of the experience source tree either.
	local top = topLevelAncestor(source)
	if EXCLUDED_TOP_LEVEL[top.ClassName] or EXCLUDED_TOP_LEVEL[top.Name] then
		return false
	end

	return true
end

local function assertSyncEligible(source: LuaSourceContainer)
	assert(isSyncEligible(source), source:GetFullName() .. " is excluded from GitHub sync")
end

local function encodedInstanceName(name: string): string
	-- Git tree paths use '/' as a directory separator, so escape only characters
	-- that would make an Instance name ambiguous as one path segment. Keeping
	-- normal spaces/dots readable makes the repository pleasant to browse.
	if name == "" then
		return "%00EMPTY"
	end

	local escaped = name:gsub("%%", "%%25")
	escaped = escaped:gsub("/", "%%2F")
	escaped = escaped:gsub("\\", "%%5C")
	escaped = escaped:gsub("[%z\1-\31\127]", function(character)
		return string.format("%%%02X", string.byte(character))
	end)

	if escaped == "." then
		return "%2E"
	elseif escaped == ".." then
		return "%2E%2E"
	end

	return escaped
end

local function extensionFor(source: LuaSourceContainer): string
	if source:IsA("ModuleScript") then
		return ".luau"
	end

	if source:IsA("LocalScript") then
		return ".client.luau"
	end

	-- A Script can also explicitly use Client RunContext in modern Studio.
	local scriptObject = source :: Script
	if scriptObject.RunContext == Enum.RunContext.Client then
		return ".client.luau"
	end

	return ".server.luau"
end

local function explicitRepoPathFor(source: LuaSourceContainer): string?
	local override = source:GetAttribute("GitHubPath")
	if typeof(override) == "string" and trim(override) ~= "" then
		local path = trim(override)
		validateRepoRelativePath(path)
		return path
	end

	return nil
end

local function collisionIdFor(source: LuaSourceContainer): string?
	local value = source:GetAttribute(COLLISION_ID_ATTRIBUTE)
	if typeof(value) == "string" and value ~= "" then
		return value
	end
	return nil
end

local function generateCollisionId(): string
	-- GenerateGUID(false) returns a random 128-bit GUID. Removing punctuation
	-- gives us a filename-safe identifier while keeping plenty of entropy.
	return HttpService:GenerateGUID(false):gsub("%-", ""):lower()
end

local function assignFreshCollisionId(source: LuaSourceContainer): string
	local id = generateCollisionId()
	source:SetAttribute(COLLISION_ID_ATTRIBUTE, id)
	return id
end

local function automaticRepoPath(source: LuaSourceContainer): string
	local segments: {string} = {}
	local current = source.Parent

	while current and current ~= game do
		table.insert(segments, 1, encodedInstanceName(current.Name))
		current = current.Parent
	end

	local suffix = ""
	local collisionId = collisionIdFor(source)
	if collisionId then
		suffix = "__" .. collisionId:sub(1, COLLISION_ID_PATH_LENGTH)
	end

	table.insert(segments, encodedInstanceName(source.Name) .. suffix .. extensionFor(source))

	local relativePath = table.concat(segments, "/")
	if config.Root == "" then
		return relativePath
	end

	return config.Root .. "/" .. relativePath
end

local function repoPathFor(source: LuaSourceContainer): string
	local explicitPath = explicitRepoPathFor(source)
	if explicitPath then
		return explicitPath
	end

	return automaticRepoPath(source)
end

local function getAllSources(): {LuaSourceContainer}
	local result: {LuaSourceContainer} = {}

	for _, instance in ipairs(game:GetDescendants()) do
		if isSourceContainer(instance) then
			local source = instance :: LuaSourceContainer
			if isSyncEligible(source) then
				table.insert(result, source)
			end
		end
	end

	return result
end

local function collectPathCollisions(sources: {LuaSourceContainer}): {[string]: {LuaSourceContainer}}
	local grouped: {[string]: {LuaSourceContainer}} = {}

	for _, source in ipairs(sources) do
		local path = repoPathFor(source)
		local group = grouped[path]
		if group then
			table.insert(group, source)
		else
			grouped[path] = {source}
		end
	end

	local collisions: {[string]: {LuaSourceContainer}} = {}
	for path, group in pairs(grouped) do
		if #group > 1 then
			collisions[path] = group
		end
	end

	return collisions
end

local function ensureUniqueRepoPaths(sources: {LuaSourceContainer})
	-- Roblox permits multiple siblings with the exact same Name, so GetFullName()
	-- and a hierarchy-based file path are not guaranteed to be unique.
	--
	-- For automatic paths, resolve those collisions by assigning a persistent
	-- GUID attribute to the colliding source objects and adding a short form of
	-- that GUID to the filename. Explicit GitHubPath overrides remain exact:
	-- if two explicit overrides collide, that is still treated as a config error.
	for _ = 1, 5 do
		local collisions = collectPathCollisions(sources)
		if next(collisions) == nil then
			return
		end

		local changedSomething = false

		for path, group in pairs(collisions) do
			local explicitCount = 0
			local automaticSources: {LuaSourceContainer} = {}

			for _, source in ipairs(group) do
				if explicitRepoPathFor(source) then
					explicitCount += 1
				else
					table.insert(automaticSources, source)
				end
			end

			if explicitCount > 1 then
				local names: {string} = {}
				for _, source in ipairs(group) do
					table.insert(names, source:GetFullName())
				end

				error(string.format(
					"Multiple Studio scripts explicitly use the same GitHubPath:\n%s\nPath: %s\nChange one of the GitHubPath attributes.",
					table.concat(names, "\n"),
					path
					))
			end

			if #automaticSources == 0 then
				error("Could not resolve duplicate GitHub path: " .. path)
			end

			-- If all automatic scripts still have no ID, this is the common
			-- same-name sibling case. Give every one a persistent ID.
			local anyExistingId = false
			for _, source in ipairs(automaticSources) do
				if collisionIdFor(source) then
					anyExistingId = true
					break
				end
			end

			if not anyExistingId then
				for _, source in ipairs(automaticSources) do
					assignFreshCollisionId(source)
					changedSomething = true
				end
			else
				-- A cloned script can inherit the original EchoGitSyncId.
				-- Keep the first automatic source's existing ID when possible
				-- and regenerate IDs for the remaining colliding sources.
				local keptExistingId = false
				for _, source in ipairs(automaticSources) do
					if collisionIdFor(source) and not keptExistingId then
						keptExistingId = true
					else
						assignFreshCollisionId(source)
						changedSomething = true
					end
				end
			end
		end

		if not changedSomething then
			break
		end
	end

	-- A remaining collision here is extremely unlikely unless a manual
	-- GitHubPath conflicts with an automatically generated suffixed path.
	local remaining = collectPathCollisions(sources)
	if next(remaining) ~= nil then
		for path, group in pairs(remaining) do
			local names: {string} = {}
			for _, source in ipairs(group) do
				table.insert(names, source:GetFullName())
			end
			error(string.format(
				"Could not automatically resolve GitHub path collision:\n%s\nPath: %s\nSet a unique GitHubPath attribute on one of these scripts.",
				table.concat(names, "\n"),
				path
				))
		end
	end
end

local function assertSelectedPathIsUnique(source: LuaSourceContainer)
	local sources = getAllSources()
	ensureUniqueRepoPaths(sources)

	local selectedPath = repoPathFor(source)
	for _, other in ipairs(sources) do
		if other ~= source and repoPathFor(other) == selectedPath then
			error(string.format(
				"%s and %s both map to %s. Set a unique GitHubPath attribute before syncing either script.",
				source:GetFullName(),
				other:GetFullName(),
				selectedPath
				))
		end
	end
end

local function editorSourceFor(source: LuaSourceContainer): string
	local success, result = pcall(function()
		return ScriptEditorService:GetEditorSource(source)
	end)

	if not success then
		error("Could not read edit-time source for " .. source:GetFullName() .. ": " .. tostring(result))
	end

	return result :: string
end

local function buildEntry(source: LuaSourceContainer): SourceEntry
	return {
		Path = repoPathFor(source),
		Content = editorSourceFor(source),
		Source = source,
	}
end

local function buildAllEntries(): {SourceEntry}
	local sources = getAllSources()
	ensureUniqueRepoPaths(sources)

	local entries: {SourceEntry} = {}
	for _, source in ipairs(sources) do
		table.insert(entries, buildEntry(source))
	end

	table.sort(entries, function(a, b)
		return a.Path < b.Path
	end)

	return entries
end

----------------------------------------------------------------
-- GITHUB HTTP CLIENT
----------------------------------------------------------------

local function encodeUrlPath(path: string): string
	local encodedSegments: {string} = {}
	for _, segment in ipairs(string.split(path, "/")) do
		table.insert(encodedSegments, HttpService:UrlEncode(segment))
	end
	return table.concat(encodedSegments, "/")
end

local function repoApiPrefix(): string
	return "/repos/" .. HttpService:UrlEncode(config.Owner) .. "/" .. HttpService:UrlEncode(config.Repo)
end

local function githubErrorMessage(response: HttpResponse): string
	local apiMessage = ""
	if response.Body ~= "" then
		local decodedOk, decoded = pcall(function()
			return HttpService:JSONDecode(response.Body)
		end)
		if decodedOk and typeof(decoded) == "table" and typeof(decoded.message) == "string" then
			apiMessage = decoded.message
		end
	end

	if apiMessage ~= "" then
		return string.format("GitHub HTTP %d %s: %s", response.StatusCode, response.StatusMessage, apiMessage)
	end

	return string.format("GitHub HTTP %d %s", response.StatusCode, response.StatusMessage)
end

local function shouldRetryStatus(statusCode: number): boolean
	return statusCode == 429 or statusCode == 502 or statusCode == 503 or statusCode == 504
end

local function githubRequest(method: string, endpoint: string, body: any?): any
	validateConfig()

	local headers: {[string]: string} = {
		["accept"] = "application/vnd.github+json",
		["authorization"] = "Bearer " .. token,
		["x-github-api-version"] = API_VERSION,
	}

	local encodedBody: string? = nil
	if body ~= nil then
		headers["content-type"] = "application/json"
		encodedBody = HttpService:JSONEncode(body)
	end

	local lastFailure = "Unknown HTTP failure"

	for attempt = 1, MAX_HTTP_ATTEMPTS do
		local requestOptions: {[string]: any} = {
			Url = API_ORIGIN .. endpoint,
			Method = method,
			Headers = headers,
		}
		if encodedBody then
			requestOptions.Body = encodedBody
		end

		local sent, responseOrError = pcall(function()
			return HttpService:RequestAsync(requestOptions)
		end)

		if sent then
			local response = responseOrError :: HttpResponse
			if response.Success then
				if response.Body == "" then
					return nil
				end
				return HttpService:JSONDecode(response.Body)
			end

			lastFailure = githubErrorMessage(response)
			if not shouldRetryStatus(response.StatusCode) then
				error(lastFailure)
			end
		else
			lastFailure = "HTTP request could not be sent: " .. tostring(responseOrError)
		end

		if attempt < MAX_HTTP_ATTEMPTS then
			task.wait(2 ^ attempt)
		end
	end

	error(lastFailure)
end

----------------------------------------------------------------
-- GIT DATABASE OPERATIONS
----------------------------------------------------------------

local function getHeadState(): HeadState
	local branchPath = encodeUrlPath(config.Branch)
	local reference = githubRequest("GET", repoApiPrefix() .. "/git/ref/heads/" .. branchPath, nil)
	assert(typeof(reference) == "table" and typeof(reference.object) == "table" and typeof(reference.object.sha) == "string", "GitHub returned an invalid branch reference")

	local commitSha = reference.object.sha :: string
	local commit = githubRequest("GET", repoApiPrefix() .. "/git/commits/" .. commitSha, nil)
	assert(typeof(commit) == "table" and typeof(commit.tree) == "table" and typeof(commit.tree.sha) == "string", "GitHub returned an invalid commit object")

	return {
		CommitSha = commitSha,
		TreeSha = commit.tree.sha :: string,
	}
end

local function repoPathExists(treeSha: string, repoPath: string): boolean
	local tree = githubRequest("GET", repoApiPrefix() .. "/git/trees/" .. treeSha .. "?recursive=1", nil)
	assert(typeof(tree) == "table" and typeof(tree.tree) == "table", "GitHub returned an invalid tree")

	if tree.truncated == true then
		error("GitHub returned a truncated recursive tree. This repository is too large for Create This existence checks using this plugin version.")
	end

	for _, item in ipairs(tree.tree) do
		if typeof(item) == "table" and item.path == repoPath then
			return true
		end
	end

	return false
end

local function createTree(baseTreeSha: string, entries: {SourceEntry}): string
	local treeEntries: {any} = {}

	for _, entry in ipairs(entries) do
		table.insert(treeEntries, {
			path = entry.Path,
			mode = "100644",
			type = "blob",
			content = entry.Content,
		})
	end

	local result = githubRequest("POST", repoApiPrefix() .. "/git/trees", {
		base_tree = baseTreeSha,
		tree = treeEntries,
	})

	assert(typeof(result) == "table" and typeof(result.sha) == "string", "GitHub returned an invalid created tree")
	return result.sha :: string
end

local function createCommit(treeSha: string, parentSha: string, message: string): string
	local result = githubRequest("POST", repoApiPrefix() .. "/git/commits", {
		message = message,
		tree = treeSha,
		parents = {parentSha},
	})

	assert(typeof(result) == "table" and typeof(result.sha) == "string", "GitHub returned an invalid created commit")
	return result.sha :: string
end

local function updateBranchReference(newCommitSha: string)
	local branchPath = encodeUrlPath(config.Branch)
	githubRequest("PATCH", repoApiPrefix() .. "/git/refs/heads/" .. branchPath, {
		sha = newCommitSha,
		force = false,
	})
end

local function commitEntries(entries: {SourceEntry}, message: string): boolean
	assert(#entries > 0, "There are no scripts to sync")

	-- Capture the current branch head first. If someone else advances the branch
	-- before our final PATCH, force=false prevents us from overwriting their work.
	local head = getHeadState()
	local newTreeSha = createTree(head.TreeSha, entries)

	if newTreeSha == head.TreeSha then
		return false
	end

	local newCommitSha = createCommit(newTreeSha, head.CommitSha, message)

	local updated, updateError = pcall(function()
		updateBranchReference(newCommitSha)
	end)

	if not updated then
		local errorText = tostring(updateError)
		if errorText:find("HTTP 409", 1, true) or errorText:find("HTTP 422", 1, true) then
			error("The GitHub branch changed while this sync was running, or branch rules rejected the update. Nothing was force-pushed. Retry after checking the repository. Details: " .. errorText)
		end
		error(errorText)
	end

	return true
end

----------------------------------------------------------------
-- SYNC OPERATIONS
----------------------------------------------------------------

local function syncAll()
	local entries = buildAllEntries()
	setStatus(string.format("Preparing %d Studio scripts...", #entries))

	local changed = commitEntries(entries, string.format("Studio sync: %d scripts", #entries))
	if changed then
		setStatus(string.format("Synced %d scripts in one GitHub commit.", #entries))
	else
		setStatus("Sync All finished: GitHub already matches Studio.")
	end
end

local function syncOne(source: LuaSourceContainer)
	assertSyncEligible(source)
	assertSelectedPathIsUnique(source)
	local entry = buildEntry(source)
	local changed = commitEntries({entry}, "Studio sync: " .. entry.Path)

	if changed then
		setStatus("Synced " .. entry.Path)
	else
		setStatus("No changes for " .. entry.Path)
	end
end

local function createOne(source: LuaSourceContainer)
	assertSyncEligible(source)
	assertSelectedPathIsUnique(source)
	local entry = buildEntry(source)
	local head = getHeadState()

	if repoPathExists(head.TreeSha, entry.Path) then
		error("Create This refused to overwrite existing file: " .. entry.Path .. ". Use Sync This if you want to update it.")
	end

	-- Use the exact head we checked above so the create and existence check refer
	-- to the same repository snapshot.
	local newTreeSha = createTree(head.TreeSha, {entry})
	local newCommitSha = createCommit(newTreeSha, head.CommitSha, "Studio create: " .. entry.Path)

	local updated, updateError = pcall(function()
		updateBranchReference(newCommitSha)
	end)

	if not updated then
		error("The branch changed or rejected the create before it could be published. Nothing was force-pushed. Retry the operation. Details: " .. tostring(updateError))
	end

	setStatus("Created " .. entry.Path)
end

local function testConnection()
	local head = getHeadState()
	setStatus("GitHub connection OK. Branch head: " .. head.CommitSha:sub(1, 7))
end

----------------------------------------------------------------
-- TOOLBAR / ACTIONS
----------------------------------------------------------------

local toolbar = plugin:CreateToolbar("Echo Git Sync")

local syncAllButton = toolbar:CreateButton("EchoGitSyncAll", "Create/update all Studio scripts on GitHub", "", "Sync All")
local syncThisButton = toolbar:CreateButton("EchoGitSyncThis", "Sync the next Script/LocalScript/ModuleScript you select", "", "Sync This")
local createThisButton = toolbar:CreateButton("EchoGitCreateThis", "Create the next selected Script/LocalScript/ModuleScript as a new GitHub file", "", "Create This")
local settingsButton = toolbar:CreateButton("EchoGitSettings", "Configure repository and GitHub token", "", "Settings")

for _, button in ipairs({syncAllButton, syncThisButton, createThisButton, settingsButton}) do
	button.ClickableWhenViewportHidden = true
end

local syncAllAction = plugin:CreatePluginAction(
	"EchoGitSyncAllAction",
	"Echo Git Sync: Sync All",
	"Create/update every Studio script on GitHub",
	"",
	true
)

local syncThisAction = plugin:CreatePluginAction(
	"EchoGitSyncThisAction",
	"Echo Git Sync: Sync This",
	"Sync the next selected Studio script",
	"",
	true
)

local createThisAction = plugin:CreatePluginAction(
	"EchoGitCreateThisAction",
	"Echo Git Sync: Create This",
	"Create the next selected Studio script as a new GitHub file",
	"",
	true
)

----------------------------------------------------------------
-- SETTINGS WIDGET
----------------------------------------------------------------

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	false,
	false,
	380,
	460,
	320,
	380
)

local settingsWidget = plugin:CreateDockWidgetPluginGuiAsync("EchoGitSyncSettingsV1", widgetInfo)
settingsWidget.Title = "Echo Git Sync Settings"

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.BackgroundTransparency = 1
mainFrame.Size = UDim2.fromScale(1, 1)
mainFrame.Parent = settingsWidget

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = mainFrame

local function makeLabel(text: string, height: number?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, height or 20)
	label.Text = text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Font = Enum.Font.SourceSans
	label.TextSize = 16
	label.Parent = mainFrame
	return label
end

local function makeBox(initialText: string, placeholder: string): TextBox
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 0, 30)
	box.Text = initialText
	box.PlaceholderText = placeholder
	box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Font = Enum.Font.Code
	box.TextSize = 15
	box.Parent = mainFrame
	return box
end

makeLabel("GitHub owner")
local ownerBox = makeBox(config.Owner, "EchoStorms")

makeLabel("Repository")
local repoBox = makeBox(config.Repo, "The-Obby")

makeLabel("Branch")
local branchBox = makeBox(config.Branch, "main")

makeLabel("Repository root (empty = repo root)")
local rootBox = makeBox(config.Root, "src")

makeLabel("Fine-grained GitHub token (leave blank to keep the saved token)")
local tokenBox = makeBox("", if token ~= "" then "Token already saved" else "Paste token, then Save")

local buttonRow = Instance.new("Frame")
buttonRow.BackgroundTransparency = 1
buttonRow.Size = UDim2.new(1, 0, 0, 32)
buttonRow.Parent = mainFrame

local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.Padding = UDim.new(0, 6)
rowLayout.Parent = buttonRow

local function makeRowButton(text: string, widthScale: number): TextButton
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(widthScale, -4, 1, 0)
	button.Text = text
	button.Font = Enum.Font.SourceSansSemibold
	button.TextSize = 15
	button.Parent = buttonRow
	return button
end

local saveSettingsButton = makeRowButton("Save", 0.34)
local testSettingsButton = makeRowButton("Test", 0.33)
local clearTokenButton = makeRowButton("Clear Token", 0.33)

statusLabel = makeLabel("Ready.", 46)
statusLabel.TextWrapped = true

----------------------------------------------------------------
-- BUSY STATE / EXECUTION WRAPPER
----------------------------------------------------------------

local busy = false

local function setOperationButtonsEnabled(enabled: boolean)
	syncAllButton.Enabled = enabled
	syncThisButton.Enabled = enabled
	createThisButton.Enabled = enabled
	testSettingsButton.Active = enabled
	testSettingsButton.AutoButtonColor = enabled
end

local function runExclusive(label: string, callback: () -> ())
	if busy then
		setStatus("Already busy with another GitHub operation.", true)
		return
	end

	busy = true
	setOperationButtonsEnabled(false)
	setStatus(label .. "...")

	task.spawn(function()
		local success, result = pcall(callback)
		busy = false
		setOperationButtonsEnabled(true)

		if not success then
			setStatus(tostring(result), true)
		end
	end)
end

----------------------------------------------------------------
-- NEXT-SELECTION MODES
----------------------------------------------------------------

local armedMode: SelectionMode? = nil
local selectionConnection: RBXScriptConnection? = nil

local function disarmSelectionMode(message: string?)
	armedMode = nil
	if selectionConnection then
		selectionConnection:Disconnect()
		selectionConnection = nil
	end
	if message then
		setStatus(message)
	end
end

local function armSelectionMode(mode: SelectionMode)
	if busy then
		setStatus("Wait for the current GitHub operation to finish first.", true)
		return
	end

	if armedMode == mode then
		disarmSelectionMode(mode .. " selection cancelled.")
		return
	end

	disarmSelectionMode()
	armedMode = mode
	setStatus(mode .. " armed: select one Script, LocalScript, or ModuleScript next.")

	selectionConnection = Selection.SelectionChanged:Connect(function()
		local selected = Selection:Get()
		local sourceCandidates: {LuaSourceContainer} = {}

		for _, instance in ipairs(selected) do
			if isSourceContainer(instance) then
				table.insert(sourceCandidates, instance :: LuaSourceContainer)
			end
		end

		if #sourceCandidates == 0 then
			return
		end

		if #sourceCandidates ~= 1 then
			setStatus("Select exactly one script for " .. mode .. ".", true)
			return
		end

		local source = sourceCandidates[1]
		disarmSelectionMode()

		if mode == "Sync" then
			runExclusive("Syncing " .. source:GetFullName(), function()
				syncOne(source)
			end)
		else
			runExclusive("Creating " .. source:GetFullName(), function()
				createOne(source)
			end)
		end
	end)
end

----------------------------------------------------------------
-- SETTINGS HANDLERS
----------------------------------------------------------------

local function saveSettings()
	local newConfig: Config = {
		Owner = trim(ownerBox.Text),
		Repo = trim(repoBox.Text),
		Branch = trim(branchBox.Text),
		Root = trim(rootBox.Text),
	}

	local previousConfig = config
	config = newConfig

	local ok, validationError = pcall(function()
		validateSimpleName(config.Owner, "Owner")
		validateSimpleName(config.Repo, "Repository")
		assert(config.Branch ~= "", "Branch cannot be empty")
		validateRepoRelativePath(config.Root, true)
	end)

	if not ok then
		config = previousConfig
		setStatus(tostring(validationError), true)
		return
	end

	plugin:SetSetting(KEY_OWNER, config.Owner)
	plugin:SetSetting(KEY_REPO, config.Repo)
	plugin:SetSetting(KEY_BRANCH, config.Branch)
	plugin:SetSetting(KEY_ROOT, config.Root)

	local enteredToken = trim(tokenBox.Text)
	if enteredToken ~= "" then
		token = enteredToken
		plugin:SetSetting(KEY_TOKEN, token)
		tokenBox.Text = ""
		tokenBox.PlaceholderText = "Token already saved"
	end

	setStatus("Settings saved.")
end

saveSettingsButton.Activated:Connect(saveSettings)

clearTokenButton.Activated:Connect(function()
	token = ""
	plugin:SetSetting(KEY_TOKEN, "")
	tokenBox.Text = ""
	tokenBox.PlaceholderText = "Paste token, then Save"
	setStatus("Saved GitHub token cleared.")
end)

testSettingsButton.Activated:Connect(function()
	saveSettings()
	if token == "" then
		setStatus("Save a GitHub token before testing.", true)
		return
	end
	runExclusive("Testing GitHub connection", testConnection)
end)

----------------------------------------------------------------
-- TOOLBAR / KEYBIND HANDLERS
----------------------------------------------------------------

syncAllButton.Click:Connect(function()
	disarmSelectionMode()
	runExclusive("Sync All", syncAll)
end)

syncThisButton.Click:Connect(function()
	armSelectionMode("Sync")
end)

createThisButton.Click:Connect(function()
	armSelectionMode("Create")
end)

settingsButton.Click:Connect(function()
	settingsWidget.Enabled = not settingsWidget.Enabled
end)

syncAllAction.Triggered:Connect(function()
	disarmSelectionMode()
	runExclusive("Sync All", syncAll)
end)

syncThisAction.Triggered:Connect(function()
	armSelectionMode("Sync")
end)

createThisAction.Triggered:Connect(function()
	armSelectionMode("Create")
end)

plugin.Unloading:Connect(function()
	disarmSelectionMode()
end)

setStatus("Loaded. Open Settings, save your GitHub token, then use Sync All / Sync This / Create This.")