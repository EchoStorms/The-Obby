local memory = {}
local dd = {
studs = 0,
checkpoints = {},
}
memory.players = {}
function memory:joined(plr)
	print("JOINED START:", plr.Name)
		local dataservice = require(game.ServerScriptService.dataservice)
		local data = game:GetService("DataStoreService"):GetDataStore("player_data")
		local loaded = dataservice.load(plr.UserId, data) 
		if loaded then
			self.players[plr.UserId] = loaded
			for i,v in pairs(dd) do
				if not self.players[plr.UserId][i] then
					self.players[plr.UserId][i] = v
					print(v.Name or tostring(v))
				end
			end
		else
			self.players[plr.UserId] = table.clone(dd)
		end 
		task.wait(0.1)
		self.players[plr.UserId].checkpoints = {}
print("join finished, your data had been loaded")
print(data)
			
	end
	function memory:left(plr)
		local dataservice = require(game.ServerScriptService.dataservice)
		local data = game:GetService("DataStoreService"):GetDataStore("player_data")
		dataservice.save(plr.UserId, self.players[plr.UserId], data)
	end
	function memory:UpdateStuds(plr : Player, Amount : number)
		local leaderstats = plr:FindFirstChild("leaderstats") if not leaderstats then return end
		local studs : IntValue = leaderstats:FindFirstChild("Studs")
		if not self.players[plr.UserId] then return end 
		if self.players[plr.UserId].studs then
			self.players[plr.UserId].studs += Amount
			studs.Value = self.players[plr.UserId].studs
			game.ReplicatedStorage.UpdateUI:FireClient(plr,self.players[plr.UserId].studs)
		end
	end
return memory
