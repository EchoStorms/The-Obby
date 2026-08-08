print("client can run LOL")
local clientfunctions = {
	mute = function(target,targ2)
		target.PlayerGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
	end,
	unmute = function(target,targ2)
		target.PlayerGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
	end,
}
local event = game.ReplicatedStorage:WaitForChild("event")
event.OnClientEvent:Connect(function(targ,func)
	print({targ,func})
	if not clientfunctions[func] then return end
	clientfunctions[func](targ)
end)