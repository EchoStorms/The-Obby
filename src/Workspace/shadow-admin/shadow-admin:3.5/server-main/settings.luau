local settings = {
	prefix = "/",--default prefix: type this before command
	perplayerprefix = {
		[3831493386] = "!"
		--dont worry the example wont give the player admin perms
	},--if you want to have a different prefix for a player add there user id and set it to the prefix
	privateservercommandperms = {
		--in many games you may notice commands in VIP/private servers
		--this table is for that just add the command name and set it to true 
		mute = true,
		unmute = true,
		sban = true,--server ban
		m = true,--server message
		kick = true,
		--keep using this format to add more
	},
	--[[______________________Perms/Ranks________________________]]--
--	1 = basic commands like mute and kill --
--	2 = can kick players(most commands) --
--	3 = most commands(More moderation commands) --
--	4 = shutdown server --
--	5 = do anything to the entire game  --
	--[[_________________________________________________________]]--
	StrictTarget = {
		kick = true,
		ban = true
	}
}

return settings
