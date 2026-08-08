script.Parent.Triggered:Connect(function(plr)
	script.Parent["Light Switch Sound"]:Play()
	script.Parent["Light Switch Sound"].Ended:Wait()
	if game.Workspace.Switches.Open.Value == true then
		workspace.PurpleGuy18:Destroy()
		for i,v in game.Players:GetPlayers() do
			v.DevEnableMouseLock = true
			v.Character:PivotTo(workspace.TargetCF.CFrame)
		end
	else
		local clone = script.Parent.Parent.Fail:Clone() 
		clone.Parent = plr.PlayerGui
		task.wait(1.3)
		clone.TextLabel.TextTransparency = 0.3
		clone.TextLabel.UIStroke.Transparency = 0.3
		task.wait(0.1)
		clone.TextLabel.TextTransparency = 0.4
		clone.TextLabel.UIStroke.Transparency = 0.4
		task.wait(0.1)
		clone.TextLabel.TextTransparency = 0.5
		clone.TextLabel.UIStroke.Transparency = 0.5
		task.wait(0.1)
		clone.TextLabel.TextTransparency = 0.7
		clone.TextLabel.UIStroke.Transparency = 0.7
		task.wait(0.1)
		clone.TextLabel.TextTransparency = 0.8
		clone.TextLabel.UIStroke.Transparency = 0.8
		task.wait(0.1)
		clone.TextLabel.UIStroke.Transparency = 0.95
		clone.TextLabel.TextTransparency = 0.95
		task.wait(0.1)
		clone:Destroy()
	end
end)