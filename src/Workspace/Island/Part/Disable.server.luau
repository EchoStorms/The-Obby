script.Parent.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChild("Humanoid") then
		local hum = hit.Parent:FindFirstChild("Humanoid")
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if player then
		game.ReplicatedStorage.Enabled.Value = true
		player.DevEnableMouseLock = false
		end
	end
end)