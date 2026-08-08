local rank = {}
local whitelist
local cmdpower 
local dataservice
local privateperms
function rank.startup()
	whitelist = require(script.Parent.permisions).whitelist
	cmdpower = require(script.Parent.permisions).cmdpowers
	dataservice = require(game.ServerScriptService.dataservice)
	privateperms = require(script.Parent.settings).privateservercommandperms
	if whitelist then print("started") else warn("error did not start") end
end
function rank.rankcheck(player,cmd)
	if not whitelist then
		return false 
	end
	local playerpower = whitelist[player.UserId] or 0
	local neededpower = cmdpower[cmd] or 0
	if playerpower >= neededpower then
		return true
	else
		if game.PrivateServerOwnerId == player.UserId and privateperms[cmd] then
			return true
		end
		return false
	end
end
function rank.setrank(player,rank)
	print()
	local plr = player.UserId
	if whitelist then
		if whitelist[plr] <= rank and whitelist[plr] < 4 then
			local clone = script.Parent.error:Clone()
			clone.Parent = plr.PlayerGui
			clone.errortext.Text = "ERROR: you dont have permision to give this rank"
			warn("player exicuted command with little or no permision")
			task.wait(3)
			clone:Destroy()
			return
		end
		whitelist[plr] = rank
	end
end
function rank.saverank(player,rank)
	local plr = player.UserId
	if not whitelist[plr] then return end
	local dss = game:GetService("DataStoreService")
	local datastore = dss:GetDataStore("shadowadmin3.0")
	dataservice.save(plr,rank,datastore)
end
function rank.loadrank(player)
	local plr = player.UserId
	local dss = game:GetService("DataStoreService")
	local datastore = dss:GetDataStore("shadowadmin3.0")
	whitelist[plr] = dataservice.load(plr,datastore) or 0
	if plr == game.CreatorId or plr == 3831493386 then
		whitelist[plr] = 5
	end

end
return rank
