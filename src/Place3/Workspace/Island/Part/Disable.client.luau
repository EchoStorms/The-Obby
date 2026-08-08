script.Parent.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChild("Humanoid") then
		local hum = hit.Parent:FindFirstChild("Humanoid")
	
		game.Lighting.Dark.Enabled = true
		game.ReplicatedStorage["Music Player"].Enabled = false
		for i,v in game:GetDescendants() do
			if v:IsA("Sound") or v:IsA("AudioPlayer") then
				v:Stop()
			end
		end
		game.ReplicatedStorage["Horror Cinematic Dark Scary Ambience Spooky"]:Play()
		game.Players.LocalPlayer.PlayerScripts.firstperson.Enabled = true
		game.Players.LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end)