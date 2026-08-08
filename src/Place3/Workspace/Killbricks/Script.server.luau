for i,v in script.Parent:GetChildren() do
	if v:IsA("BasePart") then
		v.Touched:Connect(function(hit)
			if hit.Parent:FindFirstChild("Humanoid") then
				local char = hit.Parent
				local damage = 100
				char.Humanoid.Health -= damage
			end
		end)
	end
end