local memory = require(game.ServerScriptService.memory)
local cost : number = 150
script.Parent.Triggered:Connect(function(plr)
	local playerdata = memory.players[plr.UserId]
	if not playerdata then warn("Problem retrieving data: Studs") return end
	print(playerdata.studs)
	if (playerdata.studs - cost) < 0 then return end
	memory:UpdateStuds(plr,-cost)
	print(playerdata.studs)
	local newtool = script.Parent.Parent.Parent:Clone()
	newtool.Parent = plr.Backpack
	newtool.Handle.Anchored = false
	newtool.Handle.ProximityPromt:Destroy()
end)