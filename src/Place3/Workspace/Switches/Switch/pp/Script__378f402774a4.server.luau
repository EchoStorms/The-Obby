local Promt : ProximityPrompt = script.Parent
function check()
	for i,v in workspace.Switches:GetChildren() do
		if v.Name == "Switch" then
			local pp = v:FindFirstChild("pp")
			if pp then
				if pp.Value.Value == false then
					return false
				else 
					continue
				end
			end
		end
	end
end
Promt.Triggered:Connect(function(Plr : Player)
	script.Parent["Light Switch Sound"]:Play()
	script.Parent.Parent.BrickColor = BrickColor.new("Lime green")
	script.Parent.Value.Value = true
	if check() ~= false then
		workspace.Switches.Open.Value = true
	end
end)