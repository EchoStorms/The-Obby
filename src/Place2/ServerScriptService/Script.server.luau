local badgeservice : BadgeService = game:GetService("BadgeService")
game.Players.PlayerAdded:Connect(function(plr)
	local succ, err = pcall(function()
		if not badgeservice:UserHasBadgeAsync(plr.UserId,2844784409894374) then
			badgeservice:AwardBadgeAsync(plr.UserId,2844784409894374)
		end
	end)
	if not succ then warn(err) end
end)