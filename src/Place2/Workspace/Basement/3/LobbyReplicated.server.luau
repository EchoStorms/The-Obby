local PortalAPI = require(game.ServerScriptService.PortalServices)--get the portal API
local num : string = script.Parent.Name
script.Parent.Center.Touched:Connect(function(hit : BasePart)
	if not hit.Parent:FindFirstChild("Humanoid") then return end
	local hum : Humanoid = hit.Parent:FindFirstChild("Humanoid")
	local plr : Player = game.Players:GetPlayerFromCharacter(hit.Parent)
	if not plr then return end
	hum.PlatformStand = true
	plr.DevEnableMouseLock = true
	PortalAPI.AddMember(num,plr)
	plr.Character.Parent = workspace
	plr.Character.HumanoidRootPart.Anchored = true
	if not plr.PlayerGui:FindFirstChild("Lobby") then
		local UIclone : ScreenGui = game.ReplicatedStorage.Portals.Lobby:Clone()
		UIclone.Parent = plr.PlayerGui
		if not PortalAPI.lobbys[num] then return end
		if not PortalAPI.lobbys[num].host then return end
		if not (PortalAPI.lobbys[num].host == plr) then
			local Start = UIclone:FindFirstChild("Start")
			if Start then Start:Destroy() end
		end 
	end
end)
game.ReplicatedStorage.Portals.Start.OnServerEvent:Connect(function()
	if PortalAPI.CheckLobby(num) then
		print("worked")
		PortalAPI.TeleportLobby(num)
	end
end)
game.ReplicatedStorage.Portals.Stop.OnServerEvent:Connect(function(plrs)
	plrs.Character.HumanoidRootPart.Anchored = false
	local hum : Humanoid = plrs.Character.Humanoid
	if not hum then return nil end
	hum.PlatformStand = false
	local Cframe = CFrame.new(-366.927, -310, 636.808)
	plrs.Character:PivotTo(Cframe)
	PortalAPI.RemoveMember(num,plrs)
	local GUI = plrs.PlayerGui:FindFirstChild("Lobby")
	if GUI then GUI:Destroy() end
end)
task.spawn(function()

end)