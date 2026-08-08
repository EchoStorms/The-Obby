local memory = require(game.ServerScriptService.memory)
game.Players.PlayerAdded:Connect(function(plr : Player)
local leaderstats : Folder = Instance.new("Folder")
leaderstats.Name = "leaderstats"
local studs : IntValue = Instance.new("IntValue")
studs.Name = "Studs"
leaderstats.Parent = plr
studs.Parent = leaderstats
task.wait(2)
	memory:UpdateStuds(plr,0)
end)
