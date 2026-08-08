print("running")
local announce = game.ReplicatedStorage:WaitForChild("announce")
print("found announce")
announce.OnClientEvent:Connect(function(sender : string, message : string)
	local newGUI = script.Parent.Announcement:Clone()
	newGUI.TextLabel.Text = sender
	newGUI.TextLabel.Font = Enum.Font.GothamBold
	newGUI.message.Text = message
	newGUI.message.Font = Enum.Font.RobotoMono
	newGUI.Parent = game.Players.LocalPlayer.PlayerGui.announcement.List
	game.Debris:AddItem(newGUI,5)
end)