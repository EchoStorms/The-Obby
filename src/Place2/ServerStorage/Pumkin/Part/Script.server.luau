local TPS : TeleportService = game:GetService("TeleportService")
script.Parent.Touched:Connect(function(hit)
	local succ,err = pcall(function()
		if hit.Parent:FindFirstChild("Humanoid") then
			local plr : Player = game.Players:GetPlayerFromCharacter(hit.Parent)
			TPS:TeleportAsync(97129097218003,{plr})
		end
	end)
end)