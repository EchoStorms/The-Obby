for i,v in script.Parent:GetChildren() do
	if v:IsA("BasePart") then
		v.Touched:Connect(function(hit)
			v.CanTouch = false
			for i = 1, 4 do
				task.wait(0.1)
				v.Transparency = math.clamp(v.Transparency + 0.25,0,1)
			end
			v.CanCollide = false
			task.wait(1)
			for i = 1, 4 do
				task.wait(0.1)
				v.Transparency = math.clamp(v.Transparency - 0.25,0,1)
			end
			v.CanCollide = true
			v.CanTouch = true
		end)
	end
end