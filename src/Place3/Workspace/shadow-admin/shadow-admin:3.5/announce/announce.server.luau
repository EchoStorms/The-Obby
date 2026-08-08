local announce = Instance.new("RemoteEvent")
announce.Name = "announce"
announce.Parent = game.ReplicatedStorage
local ui = script.Parent.Announcement
local ms = game:GetService("MessagingService")
ms:SubscribeAsync("global", function(message)
	print(message.Data)
	announce:FireAllClients(tostring(message.Data.sender),tostring(message.Data.message))
end)
