--//shadow admin 3.0 chat handler\\--
--// variables\\--
local rank = require(script.Parent.rank)
local event = Instance.new("RemoteEvent")
event.Name = "event"
event.Parent = game.ReplicatedStorage
local role = Instance.new("RemoteEvent")
role.Name = "role"
role.Parent = game.ReplicatedStorage
local role1 = Instance.new("RemoteEvent")
role1.Name = "role1"
role1.Parent = game.ReplicatedStorage
local settings = require(script.Parent.settings)
local serverbans = {}--this is not saved and is purly temporary
local commands = require(script.Parent.Commands)
local whitelist = require(script.Parent.permisions).whitelist
script.Parent.Parent.client.fly.Parent = game.StarterPlayer.StarterCharacterScripts
rank.startup()--rank module script handles all the ranks and permissions and rank secutity checks
--strict target is a table of commands that will not work without the full username(/ban)
local stricttarget = require(script.Parent.settings).StrictTarget
--save and load whitelist
local dss = game:GetService("DataStoreService")
local datastore = dss:GetDataStore("shadowadmin3.0")
local module = require(game.ServerScriptService.dataservice)
local privateperms = require(script.Parent.settings).privateservercommandperms
if not commands then
	print("loading failed")
end
--//handler\\--
game.Players.PlayerAdded:Connect(function(plr)
	--check if they are serevr banned
	if table.find(serverbans,plr.UserId) then
		plr:Kick("you where server banned by a server admin or private server owner")
	end
	--chat handler
	rank.loadrank(plr)--gets there rank
	plr.Chatted:Connect(function(message)
		--// build args \\--
		--get there command
		if message:sub(1,1) ~= settings.prefix and message:sub(1,1) ~= settings.perplayerprefix[plr.UserId] then
			return 
		end
		local target = nil
		local parts = string.split(message," ")
		if parts[2] then
			for i,v in ipairs(game.Players:GetPlayers()) do
				if string.find(string.lower(v.Name),string.lower(parts[2])) then
					target = v 
					break
				end
			end
		end
		local cmd = parts[1]:sub(2):lower()
		--build args
		local args = {
			plr = plr,
			parts = parts,
			target = target or (not stricttarget[cmd] and plr or nil)
		}

		--//fire command\\
		if commands[cmd] and rank.rankcheck(plr,cmd) then
			commands[cmd](args)
		elseif commands[cmd] then
			warn("no permsisions please ask the admin/owner for more perms to use this command.")
		else
			warn("404: command not found please try a differemt command keyword")
		end
		
	end)
end)

game.ReplicatedStorage:WaitForChild("role").OnServerEvent:Connect(function(plr,target,ranks)
	if not target or not ranks then return end
	rank.setrank(target,ranks)
	rank.saverank(target,ranks)
end)
--data stores
game.Players.PlayerRemoving:Connect(function(plr)
	if not plr.UserId then return nil end
	if plr.UserId == game.PrivateServerOwnerId then return end
	rank.saverank(plr,whitelist[plr.UserId])
end)
