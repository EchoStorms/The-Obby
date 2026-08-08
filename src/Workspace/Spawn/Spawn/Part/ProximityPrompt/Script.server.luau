script.Parent.Triggered:Connect(function(plr)
	local hum : Humanoid = plr.Character:WaitForChild("Humanoid")
	hum.Health = 0
end)