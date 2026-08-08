--declared vars
local camera = workspace.CurrentCamera
local player = game.Players.LocalPlayer
local renderservice = game:GetService("RunService")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
humanoid.AutoRotate = false
player.CameraMode = Enum.CameraMode.Classic
local cameraoffset = Vector3.new(0,0.05,-0.6)
--align orientation settings
local ao = Instance.new("AlignOrientation")
if not character:FindFirstChild("HumanoidRootPart") then return end
ao.Parent = character.HumanoidRootPart
ao.Attachment0 = character.HumanoidRootPart.RootAttachment
ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
ao.Responsiveness = 75
ao.MaxTorque = math.huge
ao.MaxAngularVelocity = 20
ao.RigidityEnabled = false
--a.o. setup finished
camera.CameraSubject = humanoid
print("setup done")
--first person function
function fire()
	renderservice.RenderStepped:Connect(function()--per frame loop
		local hrp = character:FindFirstChild("HumanoidRootPart")
		local pos = Vector3.new(0,0,camera.CFrame.Position.Z + 1.5)
		local cf = camera.CFrame
		local lookvector = cf.LookVector
		local flatlook = Vector3.new(lookvector.X,0,lookvector.Z)
		ao.CFrame = CFrame.new(Vector3.zero,flatlook)
		camera.CFrame = CFrame.new(cf.Position + cf:VectorToWorldSpace(cameraoffset)) * (cf - cf.Position)
	for i,v in pairs(character:GetChildren()) do
			if v:IsA("BasePart") and v.Name ~="Head" then
			character.Humanoid.CameraOffset = cameraoffset
				v.LocalTransparencyModifier = 0
			
			end
		end
	end)
end
repeat wait() until character:FindFirstChild("Head")
print("fired")
fire()

