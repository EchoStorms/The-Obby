local debounce = false
local ps = game:GetService("PathfindingService")
local npc = script.Parent
local hum = npc:WaitForChild("Humanoid")
local hrp = npc:WaitForChild("HumanoidRootPart")
local closest = nil
hum.WalkSpeed = 13.8
local maxnopath = 25
local nopathcount = 0
local enabled = game.ReplicatedStorage.Enabled
hrp:SetNetworkOwner(nil)

function gettarget()
	closest = nil
	local smallest = math.huge
	for i,v in ipairs(game.Players:GetPlayers()) do
		local char = v.Character 
			if not char then break end
			local distance = (char.HumanoidRootPart.Position - hrp.Position).Magnitude
			if distance < smallest then
				smallest = distance
				closest = v.Character.HumanoidRootPart
			end
		end
	return closest
end
function moveto(destination)
	if game.ReplicatedStorage.Enabled.Value == false then return nil end
	local path = ps:CreatePath({
		AgentRadius = 2.5,
		AgentHeight = 8,
		AgentCanJump = true,
		AgentJumpHeight = 10,
		AgentMaxSlope = 45,
		AgentCanClimb = true,
	})

	path:ComputeAsync(hrp.Position, destination.Position)
	print("PATH STATUS:", path.Status)
	if path.Status == Enum.PathStatus.NoPath then
		nopathcount += 1
	end
	if nopathcount >= maxnopath then
		nopathcount = 0
		local target = gettarget()
		if not target then return end
		hum.Parent:PivotTo(target.CFrame)
	end
	if path.Status == Enum.PathStatus.Success then
		nopathcount = 0
		local waypoints = path:GetWaypoints()
		for index, wp in ipairs(waypoints) do
			if index == 1 then
				continue
			end
			hum:MoveTo(wp.Position)
			if index >= 4 then
				break
			end
		end
	end
end
task.spawn(function()
while wait() do
	if enabled.Value == true then
		print(enabled.Value)
		local target = gettarget()
			if target then
			moveto(target)
			end	
		end
	end
end)
local lower = npc:FindFirstChild("Left Leg")
lower.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChild("Humanoid") and hit.Parent.Name ~= script.Parent.Name and debounce == false then
		debounce = true
		hit.parent.Humanoid:TakeDamage(20)
		if hit.Parent.Humanoid.Health <= 0 then
			game.ReplicatedStorage.scary_scream_glitch_V2:Play()
			local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
			game.ReplicatedStorage.Enabled.Value = false
			game.ReplicatedStorage.scary_scream_glitch_V2.Ended:Wait()
			game.ReplicatedStorage.Enabled.Value = false
			for i,v in game.Players:GetPlayers() do
				local char = v.Character or v.CharacterAdded:Wait()
				char.Humanoid.Health = 0
				v.DevEnableMouseLock = true
			end
			game.ReplicatedStorage.Horror:FireAllClients()
		end
		task.wait(1)
		debounce = false
	end
end)
