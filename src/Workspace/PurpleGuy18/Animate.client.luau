local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")

local animator = humanoid:FindFirstChildOfClass("Animator")

if not animator then
	animator = Instance.new("Animator")
	animator.Parent = humanoid
end

local function loadAnimation(id, priority)
	local animation = Instance.new("Animation")
	animation.AnimationId = id

	local track = animator:LoadAnimation(animation)
	track.Priority = priority
	track.Looped = true

	return track
end

local idleTrack = loadAnimation(
	"rbxassetid://180435571",
	Enum.AnimationPriority.Idle
)

local walkTrack = loadAnimation(
	"rbxassetid://180426354",
	Enum.AnimationPriority.Movement
)

idleTrack:Play()

humanoid.Running:Connect(function(speed)
	if speed > 0.5 then
		if idleTrack.IsPlaying then
			idleTrack:Stop(0.15)
		end

		if not walkTrack.IsPlaying then
			walkTrack:Play(0.15)
		end

		walkTrack:AdjustSpeed(speed / 16)
	else
		if walkTrack.IsPlaying then
			walkTrack:Stop(0.15)
		end

		if not idleTrack.IsPlaying then
			idleTrack:Play(0.15)
		end
	end
end)