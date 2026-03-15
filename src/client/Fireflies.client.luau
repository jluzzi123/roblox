-- Fireflies.client.luau
-- Glowing particle fireflies that appear after dusk (ClockTime ~20) and vanish at dawn (~6).
-- Particles spawn around the player to create an immersive forest feel at night.

local Players    = game:GetService("Players")
local Lighting   = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp       = character:WaitForChild("HumanoidRootPart", 10)

player.CharacterAdded:Connect(function(char)
	character = char
	hrp = char:WaitForChild("HumanoidRootPart", 10)
	if fireflyPart then
		fireflyPart.Parent = char
	end
end)

-- ── FIREFLY EMITTER PART ──────────────────────────────────────────────────────
local fireflyPart = Instance.new("Part")
fireflyPart.Name         = "FireflyEmitter"
fireflyPart.Size         = Vector3.new(30, 8, 30)  -- wide spawning zone around player
fireflyPart.Anchored     = false
fireflyPart.CanCollide   = false
fireflyPart.Transparency = 1
fireflyPart.CastShadow   = false
fireflyPart.Parent       = character

local weld = Instance.new("WeldConstraint")
weld.Part0  = hrp
weld.Part1  = fireflyPart
weld.Parent = fireflyPart
fireflyPart.CFrame = hrp.CFrame * CFrame.new(0, 2, 0)

-- ── PARTICLE EMITTER ──────────────────────────────────────────────────────────
local emitter = Instance.new("ParticleEmitter")
emitter.Name          = "FireflyParticles"

-- Soft glowing dot texture (Roblox built-in circle/spark)
emitter.Texture       = "rbxassetid://241685484"   -- bright circle glow

emitter.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(180, 255, 100)),  -- yellow-green
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(220, 255, 80)),   -- bright yellow
	ColorSequenceKeypoint.new(0.7, Color3.fromRGB(160, 240, 90)),   -- fade back to green
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(140, 220, 80)),
})

emitter.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0.0, 1.0),
	NumberSequenceKeypoint.new(0.1, 0.2),
	NumberSequenceKeypoint.new(0.5, 0.15),
	NumberSequenceKeypoint.new(0.9, 0.25),
	NumberSequenceKeypoint.new(1.0, 1.0),
})

emitter.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0,   0.10),
	NumberSequenceKeypoint.new(0.5, 0.22),
	NumberSequenceKeypoint.new(1,   0.08),
})

emitter.LightEmission  = 1.0     -- fully glowing
emitter.LightInfluence = 0.0     -- not affected by world lighting
emitter.Speed          = NumberRange.new(0.3, 1.2)
emitter.SpreadAngle    = Vector2.new(180, 180)  -- emit in all directions
emitter.Rotation       = NumberRange.new(0, 360)
emitter.RotSpeed       = NumberRange.new(-20, 20)
emitter.Lifetime       = NumberRange.new(3.5, 7.0)
emitter.Rate           = 0       -- starts off
emitter.LockedToPart   = false
emitter.Parent         = fireflyPart

-- ── NIGHT FADE IN/OUT ─────────────────────────────────────────────────────────
-- Fireflies active between ClockTime 20 and 6 (wrapping through midnight)
local FADE_ON_START  = 19.5   -- start fading in
local FADE_ON_END    = 21.0   -- fully visible
local FADE_OFF_START = 5.5    -- start fading out
local FADE_OFF_END   = 7.0    -- fully gone

local MAX_RATE    = 5   -- fireflies per second at peak
local targetRate  = 0

local function getNightBlend(hour)
	if hour >= FADE_ON_START and hour < FADE_ON_END then
		-- Fading in
		return (hour - FADE_ON_START) / (FADE_ON_END - FADE_ON_START)
	elseif hour >= FADE_ON_END or hour < FADE_OFF_START then
		-- Full night (past 21 OR before 5.5)
		if hour >= FADE_ON_END or hour < FADE_OFF_START then
			return 1
		end
	elseif hour >= FADE_OFF_START and hour < FADE_OFF_END then
		-- Fading out
		return 1 - (hour - FADE_OFF_START) / (FADE_OFF_END - FADE_OFF_START)
	end
	return 0
end

RunService.Heartbeat:Connect(function(dt)
	local hour  = Lighting.ClockTime
	local blend = getNightBlend(hour)

	targetRate = math.floor(blend * MAX_RATE + 0.5)

	-- Smoothly adjust rate
	emitter.Rate = emitter.Rate + (targetRate - emitter.Rate) * math.min(dt * 1.2, 1)
end)

print("[Fireflies] Initialized — appear at dusk, fade at dawn.")
