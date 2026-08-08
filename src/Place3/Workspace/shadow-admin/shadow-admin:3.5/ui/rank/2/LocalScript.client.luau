local plr = nil
local tg = nil
game.ReplicatedStorage.role1.OnClientEvent:Connect(function(player,target)
	plr = player
	tg = target
end)
script.Parent.Activated:Connect(function()
	local succ, err = pcall(function()
		print(script.Parent.Name)
		game.ReplicatedStorage.role:FireServer(tg, tonumber(script.Parent.Name))
		script.Parent.Parent:Destroy()
	end)
end)