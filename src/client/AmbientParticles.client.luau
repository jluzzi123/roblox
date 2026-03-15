-- AmbientParticles.client.luau
-- Falling leaves that drift down from the forest canopy.
-- An invisible part floats above the player and moves with them.
-- Subtle, continuous — makes the forest feel alive even when nothing else is moving.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp       = character:WaitForChild("HumanoidRootPart", 10)

player.CharacterAdded:Connect(function(char)
	character = char
	hrp = char:WaitForChild("HumanoidRootPart", 10)
end)

-- ── FLOATING CANOPY PART ──────────────────────────────────────────────────────
-- This part is NOT welded — it floats above the player and is repositioned each frame.
-- This lets leaves fall from a fixed height rather than following the character exactly.
local canopyPart = Instance.new("Part")
canopyPart.Name         = "LeafCanopy"
canopyPart.Size         = Vector3.new(50, 1, 50)
canopyPart.Anchored     = true          -- anchored so we manually set CFrame
canopyPart.CanCollide   = false
canopyPart.Transparency = 1
canopyPart.CastShadow   = false
canopyPart.Parent       = workspace

-- ── LEAF PARTICLE EMITTER ─────────────────────────────────────────────────────
local leafEmitter = Instance.new("ParticleEmitter")
leafEmitter.Name = "FallingLeaves"

-- Leaf texture — small square/leaf shape
leafEmitter.Texture = "rbxassetid://6101261905"  -- replace with a leaf texture if available

leafEmitter.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(88, 58, 22)),     -- dark brown
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(140, 80, 30)),    -- warm brown
	ColorSequenceKeypoint.new(0.50, Color3.fromRGB(165, 110, 35)),   -- orange-brown
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(52, 85, 28)),     -- dark green
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(72, 60, 22)),     -- olive
})

leafEmitter.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0.0, 0.3),
	NumberSequenceKeypoint.new(0.8, 0.4),
	NumberSequenceKeypoint.new(1.0, 1.0),
})

leafEmitter.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0.0, 0.22),
	NumberSequenceKeypoint.new(0.5, 0.30),
	NumberSequenceKeypoint.new(1.0, 0.18),
})

leafEmitter.LightEmission  = 0.0
leafEmitter.LightInfluence = 1.0

-- Slow downward drift with gentle sideways spread
leafEmitter.Speed          = NumberRange.new(1.5, 4.5)
leafEmitter.SpreadAngle    = Vector2.new(25, 25)
leafEmitter.EmissionDirection = Enum.NormalId.Bottom

-- Spinning as they fall
leafEmitter.Rotation       = NumberRange.new(0, 360)
leafEmitter.RotSpeed       = NumberRange.new(-90, 90)

leafEmitter.Lifetime       = NumberRange.new(4.0, 9.0)
leafEmitter.Rate           = 4         -- leaves per second — keep subtle
leafEmitter.LockedToPart   = false     -- leaves drift freely once emitted

leafEmitter.Parent = canopyPart

-- ── FOLLOW PLAYER ─────────────────────────────────────────────────────────────
-- Smooth follow so the canopy doesn't jitter with the character
local targetPos = Vector3.new(0, 0, 0)

RunService.Heartbeat:Connect(function(dt)
	if not hrp then return end
	local rootPos = hrp.Position
	-- Canopy floats 24 studs above player, follows XZ position lazily
	targetPos = Vector3.new(rootPos.X, rootPos.Y + 24, rootPos.Z)
	local currentPos = canopyPart.Position
	local smoothed = currentPos + (targetPos - currentPos) * math.min(dt * 3, 1)
	canopyPart.CFrame = CFrame.new(smoothed)
end)

print("[AmbientParticles] Falling leaves initialized.")
