local event = game.ReplicatedStorage:WaitForChild("event")
local whitelist = require(script.Parent.permisions).whitelist
local punished = {}
local commands = {
	kick = function(args)
		local target = args.target
		local reason = args.parts[2] or "kicked by admin"
		target:Kick(reason)
	end,

	mute = function(args)

		event:FireClient(args.target,args.target, "mute")
	end,

	unmute = function(args)
		event:FireClient(args.target,args.target, "unmute")
	end,

	ban = function(args)
		if args.plr.UserId == args.target.UserId then
			local errclone = script.Parent.error:Clone()
			errclone.Parent = args.plr.PlayerGui
			errclone.errortext.Text = ("you cant ban yourself! you want to be banned?")
			game.Debris:AddItem(errclone,3)
			return 
		end
		if args.plr.UserId == game.PrivateServerOwnerId and args.plr.UserId ~= game.CreatorId then
			local errclone = script.Parent.error:Clone()
			errclone.Parent = args.plr.PlayerGui
			errclone.errortext.Text = ("private server owners please use /sban for server ban")
			game.Debris:AddItem(errclone,3)
			return
		end
		local target = args.target
		local display = args.parts[2] or "banned"
		local private = args.parts[3] or "banned"
		local success,err = pcall(function()
			local banData = {
				UserId = target.UserId,
				DisplayReason = display,
				PrivateReason = private,
				ApplyToUniverse = true,
				Duration = args.parts[4] or -1,
			}
			game.Players:BanAsync(banData)
		end)
	end,

	shutdown = function(args)
		local reason = args.parts[2] or "server shutdown by admin"
		for _, player in pairs(game.Players:GetPlayers()) do
			player:Kick(reason)
		end
	end,

	tp = function(args)
		local char1 = args.target.Character
		local char2 = args.plr.Character
		char1:PivotTo(char2:GetPivot())
	end,

	kill = function(args)
		local target = args.target
		local char = target.Character
		char:FindFirstChildOfClass("Humanoid").Health = 0
	end,

	ga = function(args)
		local ms = game:GetService("MessagingService")
		local success,err = pcall(function()
			local messagedata = {
				message = table.concat(args.parts, " ", 2) or "" ,
				sender = "from ".. args.plr.Name,
			}
			ms:PublishAsync("global",messagedata)
		end) --end pcall
		if not success then print(err) end
	end,--end function

	test = function(args)
		print("test")
	end, --end test function

	rank = function(args)
		local target = args.target
		local clone = script.Parent.Parent.ui.rank:Clone()
		clone.Parent = args.plr.PlayerGui
		local plr = args.plr 
		game.ReplicatedStorage.role1:FireClient(plr,plr,target)
	end,
	fly = function(args)
		event:FireClient(args.target,args.parts[3] or 100,"fly")
	end,
	unfly = function(args)
		event:FireClient(args.target,"unfly")
	end,
	bj = function(args)
		--this command is better for r6
		args.target.Character:BreakJoints()
	end,
	speed = function(args)
		local target = args.target
		local speed = tonumber(args.parts[3]) or 16
		local char = target.Character
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		humanoid.WalkSpeed = speed
	end,
	jump = function(args)
		local targ = args.target
		local hum = targ.Character:FindFirstChildOfClass("Humanoid")
		hum.UseJumpPower = true
		local jumppower = tonumber(args.parts[3]) or 50
		hum.JumpPower = jumppower
	end,
	unrank = function(args)
		local target = args.target
		whitelist[target.UserId] = nil
		args.target:kick("rank removed kicking to refresh perms :C")
		print(whitelist[target.UserId])
	end,
	m = function(args)--m is for message aka server announcement
		local message = table.concat(args.parts, " ", 2) or "" 
		local sender = "from ".. args.plr.Name
		game.ReplicatedStorage.announce:FireAllClients(tostring(sender),tostring(message))
	end,
	noclip = function(args)
		event:FireClient(args.target,"noclip")
		event:FireClient(args.target,args.parts[3] or 100,"fly")
	end,
	clip = function(args)
		event:FireClient(args.target,"clip")
		event:FireClient(args.target,"unfly")
	end,
	jail = function(args)
		local target = args.target
		local char = target.Character
		local jail = game.ServerStorage:WaitForChild("jail",2):Clone()
		if not jail then return nil end
		jail.Name = (target.Name.."cell")
		jail:PivotTo(char:GetPivot())
		target.RespawnLocation = jail.SpawnLocation
	end,
	unjail = function(args)
		local target = args.target
		local jail = game.ServerStorage:FindFirstChild(target.Name.."cell")
		if jail then
			jail:Destroy()
		end
		
	end,
	punish = function(args)
		local target = args.target
		local char = target.Character
		local time = args.parts[3] or math.huge
		char.Parent = nil
		task.spawn(function()
			if time > 2e5 then return end
			task.wait(time)
			char.Parent = workspace
		end)
	end,
	unpunish = function(args)
		local target = args.target
		local char = target.Character
		char.Parent = workspace
	end,
	ff = function(args)
		local ff = Instance.new("ForceField")
		ff.Parent = args.target.Character
		ff.Name = "shadow-ff"
	end,
	unff = function(args)
		local ff = args.target.Character:WaitForChild("shadow-ff",2)
		if not ff then return end
		ff:Destroy()
	end,
	sit = function(args)
		local char = args.target.Character 
		if not char then return end
		local hum = char:FindFirstChild("Humanoid")
		if hum then hum.Sit = true end
	end,
	unsit = function(args)
		local char = args.target.Character 
		if not char then return end
		local hum = char:FindFirstChild("Humanoid")
		if hum then hum.Sit = false end
	end,
	freeze = function(args)
		local char = args.target.Character
		for _,part in char:GetDescendants() do
			if part:IsA("Part") then
				part.Anchored = true
			end
		end
	end,
	unfreeze = function(args)
		local char = args.target.Character
		for _,part in char:GetDescendants() do
			if part:IsA("Part") then
				part.Anchored = false
			end
		end
	end,
	sans = function(args)
		game.SoundService["MEGALOVANIA (Rareized)"]:Play()
	end,
	byesans = function(args)
		game.SoundService["MEGALOVANIA (Rareized)"]:Stop()
	end,
	purple = function(args)
		script.Parent.Parent.ui.Purple:Clone().Parent = args.target.PlayerGui
	end,
	byePurple = function(args)
		if args.target.PlayerGui:FindFirstChild("Purple") then
			args.target.PlayerGui:FindFirstChild("Purple"):Destroy()
		end
	end,

	--//add more commands here\\--
}
return commands
