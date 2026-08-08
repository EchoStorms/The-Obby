local memory = require(game.ServerScriptService.memory)
for i,v : BasePart in pairs(script.Parent:GetChildren()) do
	if v:IsA("BasePart") then
		v.Touched:Connect(function(hit)
			local hum = hit.Parent:FindFirstChild("Humanoid") if hum then
				local player = game.Players:GetPlayerFromCharacter(hit.Parent)
				if not player then return end
				if not table.find(memory.players[player.UserId].checkpoints,v.Name) then
					table.insert(memory.players[player.UserId].checkpoints,v.Name)
					memory:UpdateStuds(player,5)
					print(memory.players[player.UserId].studs)
				end
				
			end
		end)
	end
end
game.Players.PlayerAdded:Connect(function(plr)
	repeat wait(0.1) until memory.players[plr.UserId] 
	memory.players[plr.UserId].checkpoints = {}
end)