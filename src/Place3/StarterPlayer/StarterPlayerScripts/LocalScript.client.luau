local plr = game.Players.LocalPlayer
game.ReplicatedStorage.Horror.OnClientEvent:Connect(function()
local hum : Humanoid = plr.Character:FindFirstChild("Humanoid")
game.Lighting.Dark.Enabled = false
game.ReplicatedStorage["Music Player"].Enabled = true
game.Players.LocalPlayer.PlayerScripts.firstperson.Enabled = false
game.ReplicatedStorage["Horror Cinematic Dark Scary Ambience Spooky"]:Stop()
game.Players.LocalPlayer.CameraMode = Enum.CameraMode.Classic
hum.AutoRotate = true
hum.CameraOffset = Vector3.zero
workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
workspace.CurrentCamera.CameraSubject = hum
local ao = plr.Character.PrimaryPart:FindFirstChildOfClass("AlignOrientation")
if ao then ao:Destroy() end
end)