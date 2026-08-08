--varibles/services
local bd = Instance.new("BodyVelocity")
local speed = 100
local uis = game:GetService("UserInputService")
local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local parent = char:WaitForChild("HumanoidRootPart")
local runserverice = game:GetService("RunService")
local event = game.ReplicatedStorage:WaitForChild("event")
local flyenabled = false
local flybd = nil
local noclip = false
hum.AutoRotate = true
--body velocity
bd.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
bd.Velocity = Vector3.new(0,0,0)
bd.Parent = game.ReplicatedStorage
--align orientation
local alignOrientation = Instance.new("AlignOrientation")
alignOrientation.Parent = parent
alignOrientation.Attachment0 = parent.RootAttachment
alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
alignOrientation.MaxTorque = math.huge
alignOrientation.Responsiveness = 100
alignOrientation.Enabled = false
function unfly()
	if not flyenabled then return end
	if not flybd then return nil end
	local footstepssound = char.HumanoidRootPart:FindFirstChild("Running")
	print(footstepssound.Name)
	if footstepssound:IsA("Sound") then
		print("if statment passed")
		footstepssound.Volume = 0.5 
		warn("if you cant hear footspets this failed")
	end
	hum.AutoRotate = true
	alignOrientation.Enabled = false
	flyenabled = false
	hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	flybd:Destroy()
end
--main loop
runserverice.RenderStepped:Connect(function()
	if flyenabled then
		if noclip then
			for _,part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
		if not char then return nil end
		local cam = workspace.CurrentCamera
		alignOrientation.CFrame = cam.CFrame 
		local dir = cam.CFrame.LookVector
		local movedir = Vector3.new(0,0,0)
		char.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
		if uis.KeyboardEnabled then
			if uis:IsKeyDown(Enum.KeyCode.W) then
				movedir = movedir + cam.CFrame.LookVector
			end
			if uis:IsKeyDown(Enum.KeyCode.S) then
				movedir = movedir - cam.CFrame.LookVector
			end
			if uis:IsKeyDown(Enum.KeyCode.A) then
				movedir = movedir - cam.CFrame.RightVector
			end
			if uis:IsKeyDown(Enum.KeyCode.D) then
				movedir = movedir + cam.CFrame.RightVector
			end
			if uis:IsKeyDown(Enum.KeyCode.E) then
				movedir = movedir + Vector3.new(0,1,0) -- go up
			end
			if uis:IsKeyDown(Enum.KeyCode.Q) then
				movedir = movedir - Vector3.new(0,1,0) -- go down
			end
			if movedir.Magnitude > 0 then
				flybd.Velocity = movedir.Unit * speed
			else
				flybd.Velocity = Vector3.new(0,0,0) 
			end
			--// mobile support\\--
		else
			local flatview = hum.MoveDirection
			if flatview.Magnitude > 0 then
				local viewvector = cam.CFrame.LookVector
				movedir = viewvector * flatview.Magnitude
				flybd.Velocity = movedir.Unit * speed
			else
				flybd.Velocity = Vector3.new(0,0,0) 

			end
		end
	end
end)

--//togles\\--

--toggle on
event.OnClientEvent:Connect(function(flyspeed,types)
	if tostring(types) ~= "fly" then return end
	local footstepssound = char.HumanoidRootPart:FindFirstChild("Running")
	if footstepssound:IsA("Sound") then footstepssound.Volume = 0 end
	alignOrientation.Enabled = true
	if flybd then flybd:Destroy() end 
	flybd = bd:Clone()
	flybd.Parent = hum.Parent:FindFirstChild("HumanoidRootPart")
	flyenabled = true
	print("worked...")
	speed = flyspeed
	task.wait()
	hum:ChangeState(Enum.HumanoidStateType.Physics)

end)

--// toggle off\\--
event.OnClientEvent:Connect(function(types)
	if types ~= "unfly" then return end
	unfly()
end)

--//no clip toggle\\--\
event.OnClientEvent:Connect(function(types)
	if types == "noclip" then
		noclip = true
	end
end)
event.OnClientEvent:Connect(function(types)
	if types == "clip" then
		noclip = false
	end
end)