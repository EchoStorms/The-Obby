--!nonstrict
--[[] ShadowGUIs is a service to make your own admin panels
though it has one preset its still not
not an admin panel itself --]]
--//If you are making your own panel please look at the comments in CoreCommands\\
--//vars\\--
local UIs = script.Parent.Parent.ShadowGUIs--use this parent for your UI
local event : RemoteEvent = game.ReplicatedStorage:WaitForChild("event")
local ShadowGUI = {
	players = {},
	panels = {--This is a dictionary of all the admin panels in the game
		CoreCommands = {
			commands = {
				fly = {
				cmdpower = 2,
				Func = function(Sender : Player, Target : Player, Speed : number?)
						event:FireClient(Target,Speed or 100,"fly")
				end,
				},
				kill = {
					cmdpower = 1,
					Func = function(Target : Player)
						local hum : Humanoid = Target.Character:FindFirstChild("Humanoid")
						if not hum then return end
						hum.Health = 0
					end,
				},
				Kick = {
					cmdpower = 2,
					Func = function(Target : Player, Reason : string?)
						if Target and Target:IsA("Player") then
							Target:Kick(Reason or "You were kicked by a server admin.")
						end
					end,
				},
				Announce = {
					cmdPower = 2,
					Func = function(Message : string, Sender : Player)
						local ui = script.Parent.Parent.announce.announcement
						local sender = "from ".. Sender.Name
						ui.TextLabel.Text = tostring(sender)
						ui.message.Text = tostring(Message)
						game.ReplicatedStorage:WaitForChild("announce"):FireAllClients(ui)						
					end,
				},
				Ban = {
					cmdPower = 4,
					Func = function(Sender : Player, Target : Player, Reason : string)
						if Sender.UserId == Target.UserId then
							local errclone = game.Workspace["shadow-admin"]["shadow-admin:3.5"].ui.error:Clone()
							errclone.Parent = Sender.PlayerGui
							errclone.errortext.Text = ("you cant ban yourself! you want to be banned?")
							game.Debris:AddItem(errclone,3)
							return 
						end
						if Sender.UserId == game.PrivateServerOwnerId and Sender.UserId ~= game.CreatorId then
							local errclone = game.Workspace["shadow-admin"]["shadow-admin:3.5"].ui.error:Clone()
							errclone.Parent = Sender.PlayerGui
							errclone.errortext.Text = ("private server owners please use /sban for server ban")
							game.Debris:AddItem(errclone,3)
							return
						end
						local target = Target
						local display = Reason or "banned"
						local private = Reason or "banned"
						local success,err = pcall(function()
							local banData = {
								UserId = Target.UserId,
								DisplayReason = display,
								PrivateReason = private,
								ApplyToUniverse = true,
								Duration = -1
							}
							game.Players:BanAsync(banData)
						end)
					end,
				},
				shutdown = {
					cmdpower = 5,
						Func = function(Reason : string?)
							for i,v in game.Players:GetPlayers() do
							v:Kick(Reason or "Server Shutdown!")
							end
						end,
				}
			},--Put Commands and there code in here
			UI = UIs.ShadowGUI--If you are making your own panel duplicate "Template"
			--//UI costumization\\--
			
			--you can change the duplicate to your liking 
			--WHAT WILL BREAK IT:
			--One: Rename it from template
			--Two dont change any names or modify anything other than the looks in the core folder
			
		}
		
	}
}
return ShadowGUI