-- Footsteps.client.luau
-- Plays terrain-aware footstep sounds when the player walks.
-- Raycasts downward to detect the material under the player's feet.
--
-- NOTE: Replace asset IDs with your preferred footstep sounds.
-- Free footstep packs are available on the Roblox Creator Store.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid", 10)
local hrp       = character:WaitForChild("HumanoidRootPart", 10)

player.CharacterAdded:Connect(function(char)
	character = char
	humanoid  = char:WaitForChild("Humanoid", 10)
	hrp       = char:WaitForChild("HumanoidRootPart", 10)
end)

-- ── SOUND ASSET IDs ───────────────────────────────────────────────────────────
-- Replace these with verified audio IDs from the Roblox Creator Store.
local STEP_SOUNDS = {
	[Enum.Material.Grass]       = { "rbxassetid://133687456650659", "rbxassetid://110522236020035" },
	[Enum.Material.Ground]      = { "rbxassetid://133687456650659", "rbxassetid://110522236020035" },
	[Enum.Material.Mud]         = { "rbxassetid://130903686337396", "rbxassetid://129537457463566" },
	[Enum.Material.Rock]        = { "rbxassetid://80027112124187",  "rbxassetid://106302854750404" },
	[Enum.Material.Slate]       = { "rbxassetid://80027112124187",  "rbxassetid://106302854750404" },
	[Enum.Material.Sand]        = { "rbxassetid://133687456650659", "rbxassetid://110522236020035" },
	[Enum.Material.Snow]        = { "rbxassetid://133687456650659", "rbxassetid://110522236020035" },
	[Enum.Material.SmoothPlastic] = { "rbxassetid://80027112124187",  "rbxassetid://106302854750404" },
	Default                     = { "rbxassetid://133687456650659", "rbxassetid://110522236020035" },
}

local STEP_VOLUME  = 0.55
local STEP_RATE    = 0.38  -- minimum seconds between footstep sounds (at walking speed)
local RUN_RATE     = 0.25  -- step rate when running
local WALK_SPEED_THRESHOLD = 10  -- stud/s above this = running cadence

-- ── SOUND POOL ────────────────────────────────────────────────────────────────
-- Pre-create two Sound objects so we can alternate (no cut-off on rapid steps)
local soundPool = {}
for i = 1, 2 do
	local s = Instance.new("Sound")
	s.Volume    = STEP_VOLUME
	s.RollOffMaxDistance = 0  -- only heard by local player
	s.Parent    = hrp
	soundPool[i] = s
end
local soundIndex = 1

local function playStep(material)
	local sounds = STEP_SOUNDS[material] or STEP_SOUNDS.Default
	local snd = soundPool[soundIndex]
	snd.SoundId = sounds[math.random(1, #sounds)]
	snd.Volume  = STEP_VOLUME * (0.85 + math.random() * 0.30)  -- slight volume variation
	snd.PlaybackSpeed = 0.90 + math.random() * 0.20            -- slight pitch variation
	snd:Play()
	soundIndex = soundIndex % 2 + 1
end

-- ── RAYCAST PARAMS ────────────────────────────────────────────────────────────
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local function getMaterial()
	if not hrp then return Enum.Material.Grass end
	params.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(
		hrp.Position,
		Vector3.new(0, -4, 0),
		params
	)
	if hit then
		return hit.Material
	end
	return Enum.Material.Grass
end

-- ── STEP TIMER ────────────────────────────────────────────────────────────────
local timeSinceLastStep = 0
local wasMoving = false

RunService.Heartbeat:Connect(function(dt)
	if not humanoid or not hrp then return end

	-- Only play steps when on the ground and moving
	local speed       = humanoid.WalkSpeed > 0 and hrp.AssemblyLinearVelocity.Magnitude or 0
	local onGround    = humanoid.FloorMaterial ~= Enum.Material.Air
	local isMoving    = speed > 1.5 and onGround

	if not isMoving then
		wasMoving = false
		timeSinceLastStep = 0
		return
	end

	-- Play a step on the first frame of movement too
	if not wasMoving then
		wasMoving = true
		timeSinceLastStep = STEP_RATE  -- trigger a step immediately
	end

	timeSinceLastStep += dt

	local stepInterval = speed > WALK_SPEED_THRESHOLD and RUN_RATE or STEP_RATE

	if timeSinceLastStep >= stepInterval then
		timeSinceLastStep = 0
		local material = getMaterial()
		playStep(material)
	end
end)

print("[Footsteps] Initialized — terrain-aware footstep sounds active.")
