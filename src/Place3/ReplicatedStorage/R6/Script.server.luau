for i,v in script.Parent:GetChildren() do
	if v:IsA("BasePart") then
		v.CanCollide = false
		v.Changed:Connect(function()
			v.CanCollide = false
		end)
	end
end