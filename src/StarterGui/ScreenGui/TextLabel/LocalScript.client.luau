game.ReplicatedStorage.UpdateUI.OnClientEvent:Connect(function(amount : number)
	script.Parent.Text = tostring(amount)
end)