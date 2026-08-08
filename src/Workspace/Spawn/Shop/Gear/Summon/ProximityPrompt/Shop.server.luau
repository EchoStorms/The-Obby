local memory = require(game.ServerScriptService.memory)
local cost : number = 50
local SPS : number = 2
script.Parent.Triggered:Connect(function(plr)
	local playerdata = memory.players[plr.UserId]
	if not playerdata then warn("Problem retrieving data: Studs") return end
	print(playerdata.studs)
	if (playerdata.studs - cost) < 0 then return end
	memory:UpdateStuds(plr,-cost)
	print(playerdata.studs)
	local clone = game.ReplicatedStorage.R6:Clone()
	clone.Parent = game.Workspace
	task.spawn(function()
		while task.wait() do
			if not plr.Character then return end
			local Root = clone.HumanoidRootPart 
			local PlrRoot : BasePart = plr.Character:FindFirstChild("HumanoidRootPart")
			if Root and PlrRoot then
				local Dir = (PlrRoot.Position - Root.Position).Unit
				local NextPos = Root.Position + (Dir * 0.2)
				Root.CFrame = CFrame.lookAt(NextPos,PlrRoot.Position)
				for i,v in plr.Character:GetDescendants() do
					if v:IsA("BasePart") then
						v.CanCollide = true
					end
				end
				
			end
		end
	end)
end)