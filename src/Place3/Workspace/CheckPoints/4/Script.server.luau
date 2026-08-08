--!strict
--[[//Costumize\\]}--
==============================================================================================]]
local badgeID = 4443701942865659
local badgeservice = game:GetService("BadgeService")
--=============================================================================================
script.Parent.Touched:Connect(function(hit)
	local hum : Humanoid = hit.Parent:FindFirstChild("Humanoid")
	if hum then
		local player : Player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			local succ,err = pcall(function()
				if badgeservice:CheckUserBadgesAsync(player.UserId,{badgeID}) then
					print("Player already owns badge")
				else
					badgeservice:AwardBadgeAsync(player.UserId,badgeID)
					print("succ")
				end
			end)
			if not succ then print(err) end
		end
	end
end)