
local TeleportService = game:GetService("TeleportService")
local TableServices = require(game.ServerScriptService.TableServices)
type lobby = {
	host : Player,
	members : {[string] : Player},
	loopruning : boolean 
}
type LobbyDictionary = {[string] : lobby}
local portal = {
	lobbys = {} :: LobbyDictionary,
}
function portal.CreateLobby(PortalNumber : string,Host : Player)
	print("lobby made")
	local UI = Host.PlayerGui:FindFirstChild("Lobby")
portal.lobbys[PortalNumber] = {
	host = Host, 
	members = {
		[Host.Name] = Host
	},
	loopruning = false
}
	if UI then UI:WaitForChild("Players").Text = "Players: 1" end
end
function portal.AddMember(PortalNumber : string, Member : Player)
	
	if not portal.lobbys[PortalNumber] then
		portal.CreateLobby(PortalNumber,Member)
	end
	portal.lobbys[PortalNumber].members[Member.Name] = Member
	task.spawn(function()
		if portal.lobbys[PortalNumber].loopruning then return end
		portal.lobbys[PortalNumber].loopruning = true
		while true do
			if not portal.lobbys[PortalNumber] then return end
			local currentmembers = portal.lobbys[PortalNumber].members
			for i,v in pairs(currentmembers) do
				local member : Player = game.Players:FindFirstChild(i)
				if Member then
				local UI = v.PlayerGui:FindFirstChild("Lobby")
				if UI and UI.Players then UI.Players.Text = ("Players: "..tostring(#TableServices.DictionaryToArray(portal.lobbys[PortalNumber].members))) end
				end
			end
			task.wait(0.2)
		end
	end)
end
function portal.MoveHost(PortalNumber : string,Members : {})
	if not portal.lobbys[PortalNumber] then return end
	local ArrayOfMembers = TableServices.DictionaryToArray(Members)
	local RandomPlayer : number = math.random(1,#ArrayOfMembers)
	portal.lobbys[PortalNumber].host = ArrayOfMembers[RandomPlayer]
end
function portal.CheckLobby(PortalNumber : string)
	if not portal.lobbys[PortalNumber] then return false end
	local ArrayOfMembers = TableServices.DictionaryToArray(portal.lobbys[PortalNumber].members)
	if #ArrayOfMembers <= 0 then 
		return false
	else
		return true
	end
end
function portal.CloseLobby(PortalNumber : string)
	portal.lobbys[tostring(PortalNumber)] = nil
end
function portal.TeleportLobby(PortalNumber : string)
	local succ,err = pcall(function()
		local lobby = portal.lobbys[PortalNumber]
		if not lobby then return end
		if not lobby.members then return end
		local Group : {Player} = TableServices.DictionaryToArray(lobby.members) :: {Player}
		local options : TeleportOptions = Instance.new("TeleportOptions")
		local Server : string = TeleportService:ReserveServerAsync(97129097218003)
		options.ReservedServerAccessCode = Server
		TeleportService:TeleportAsync(97129097218003,Group,options)
	end)
	if not succ then warn(err) end
end
function portal.RemoveMember(PortalNumber : string,player : Player)
	if portal.CheckLobby(PortalNumber) then
		portal.lobbys[PortalNumber].members[player.Name] = nil
	end
	if not portal.CheckLobby(PortalNumber) then--we check again after to see if there are no players left
		portal.CloseLobby(PortalNumber)
	elseif player == portal.lobbys[PortalNumber].host then
		portal.MoveHost(PortalNumber,portal.lobbys[PortalNumber].members)
	end
end
return portal
