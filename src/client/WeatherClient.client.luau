-- WeatherClient.client.luau
-- Handles client-side weather visuals: rain particles, screen effects, lightning flash.
-- Receives weather state from Weather.server.luau via RemoteEvent.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local player     = Players.LocalPlayer
local camera     = workspace.CurrentCamera

-- ── WAIT FOR CHARACTER ────────────────────────────────────────────────────────
local character = player.Character or player.CharacterAdded:Wait()
local hrp       = character:WaitForChild("HumanoidRootPart", 10)

-- ── RAIN PARTICLE EMITTER ─────────────────────────────────────────────────────
local rainPart = Instance.new("Part")
rainPart.Name        = "RainEmitter"
rainPart.Size        = Vector3.new(60, 1, 60)   -- large canopy above player
rainPart.Anchored    = false
rainPart.CanCollide  = false
rainPart.Transparency = 1
rainPart.CastShadow  = false
rainPart.Parent      = character

-- Set CFrame FIRST, then create weld so offset is recorded correctly
rainPart.CFrame = hrp.CFrame * CFrame.new(0, 18, 0)
local weld = Instance.new("WeldConstraint")
weld.Part0  = hrp
weld.Part1  = rainPart
weld.Parent = rainPart

local rainEmitter = Instance.new("ParticleEmitter")
rainEmitter.Name             = "RainDrops"
rainEmitter.Texture          = "rbxassetid://6101261905"  -- thin vertical streak
rainEmitter.Color            = ColorSequence.new(Color3.fromRGB(180, 200, 230))
rainEmitter.Transparency     = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(1, 1.0),
})
rainEmitter.Size             = NumberSequence.new(0.10)
rainEmitter.LightEmission    = 0.0
rainEmitter.LightInfluence   = 1.0
rainEmitter.Speed            = NumberRange.new(28, 45)
rainEmitter.SpreadAngle      = Vector2.new(4, 4)
rainEmitter.Rotation         = NumberRange.new(0, 0)
rainEmitter.RotSpeed         = NumberRange.new(0, 0)
rainEmitter.Lifetime         = NumberRange.new(0.5, 1.2)
rainEmitter.Rate             = 0            -- starts off; enabled by weather state
rainEmitter.LockedToPart     = false
rainEmitter.EmissionDirection = Enum.NormalId.Bottom
rainEmitter.Parent           = rainPart

-- ── GROUND SPLASH EMITTER ─────────────────────────────────────────────────────
local splashPart = Instance.new("Part")
splashPart.Name         = "SplashEmitter"
splashPart.Size         = Vector3.new(8, 1, 8)
splashPart.Anchored     = false
splashPart.CanCollide   = false
splashPart.Transparency = 1
splashPart.CastShadow   = false
splashPart.Parent       = character

-- Set CFrame FIRST, then create weld
splashPart.CFrame = hrp.CFrame * CFrame.new(0, -2, 0)
local splashWeld = Instance.new("WeldConstraint")
splashWeld.Part0  = hrp
splashWeld.Part1  = splashPart
splashWeld.Parent = splashPart

local splashEmitter = Instance.new("ParticleEmitter")
splashEmitter.Name              = "RainSplash"
splashEmitter.Texture           = "rbxassetid://6101261905"
splashEmitter.Color             = ColorSequence.new(Color3.fromRGB(180, 210, 240))
splashEmitter.Transparency      = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.4),
	NumberSequenceKeypoint.new(1, 1.0),
})
splashEmitter.Size              = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.05),
	NumberSequenceKeypoint.new(1, 0.12),
})
splashEmitter.Speed             = NumberRange.new(2, 6)
splashEmitter.SpreadAngle       = Vector2.new(70, 70)
splashEmitter.Rotation          = NumberRange.new(0, 360)
splashEmitter.Lifetime          = NumberRange.new(0.2, 0.5)
splashEmitter.Rate              = 0
splashEmitter.LightInfluence    = 1.0
splashEmitter.EmissionDirection = Enum.NormalId.Top
splashEmitter.Parent            = splashPart

-- ── RESPAWN HANDLER ───────────────────────────────────────────────────────────
player.CharacterAdded:Connect(function(char)
	character = char
	hrp = char:WaitForChild("HumanoidRootPart", 10)

	rainPart.Parent   = char
	splashPart.Parent = char

	rainPart.CFrame = hrp.CFrame * CFrame.new(0, 18, 0)
	local newRainWeld = Instance.new("WeldConstraint")
	newRainWeld.Part0  = hrp
	newRainWeld.Part1  = rainPart
	newRainWeld.Parent = rainPart

	splashPart.CFrame = hrp.CFrame * CFrame.new(0, -2, 0)
	local newSplashWeld = Instance.new("WeldConstraint")
	newSplashWeld.Part0  = hrp
	newSplashWeld.Part1  = splashPart
	newSplashWeld.Parent = splashPart
end)

-- ── SCREEN COLOR CORRECTION PER WEATHER ───────────────────────────────────────
-- We layer a second ColorCorrectionEffect on top of the base atmosphere one
local weatherCC = Instance.new("ColorCorrectionEffect")
weatherCC.Name       = "WeatherColorCorrection"
weatherCC.Brightness = 0
weatherCC.Contrast   = 0
weatherCC.Saturation = 0
weatherCC.TintColor  = Color3.fromRGB(255, 255, 255)
weatherCC.Parent     = Lighting

local weatherBloom = Lighting:FindFirstChild("GameBloom")

-- Target values per state
local STATE_CC = {
	Clear    = { brightness =  0.00, contrast = 0.05, saturation = 0.05,  tint = Color3.fromRGB(255, 250, 240) },
	Overcast = { brightness = -0.04, contrast = 0.02, saturation = -0.08, tint = Color3.fromRGB(220, 225, 235) },
	Rain     = { brightness = -0.08, contrast = 0.00, saturation = -0.18, tint = Color3.fromRGB(200, 215, 235) },
	Storm    = { brightness = -0.14, contrast = 0.10, saturation = -0.28, tint = Color3.fromRGB(185, 200, 228) },
}

-- ── LIGHTNING FLASH (client-side screen pop) ──────────────────────────────────
local function doClientLightningFlash()
	-- Bright white flash, then back to normal
	local flashCC = Instance.new("ColorCorrectionEffect")
	flashCC.Name       = "LightningFlash"
	flashCC.Brightness = 1.5
	flashCC.Parent     = Lighting

	local tween = TweenService:Create(
		flashCC,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Brightness = 0 }
	)
	tween:Play()
	tween.Completed:Wait()
	flashCC:Destroy()

	-- Mild camera shake
	local shakeDuration = 0.4
	local shakeEnd = tick() + shakeDuration
	local shakeTask
	shakeTask = RunService.RenderStepped:Connect(function()
		if tick() > shakeEnd then
			shakeTask:Disconnect()
			return
		end
		local t = 1 - (shakeEnd - tick()) / shakeDuration
		local mag = 0.5 * (1 - t)
		camera.CFrame = camera.CFrame
			* CFrame.new(
				math.random() * mag - mag / 2,
				math.random() * mag - mag / 2,
				0
			)
	end)
end

-- ── WEATHER STATE HANDLING ────────────────────────────────────────────────────
local currentState    = "Clear"
local targetRainRate  = 0
local targetSplashRate = 0

local weatherRemote = ReplicatedStorage:WaitForChild("WeatherState", 15)
if weatherRemote then
	weatherRemote.OnClientEvent:Connect(function(state)
		if state == "Lightning" then
			task.spawn(doClientLightningFlash)
			return
		end

		currentState = state

		-- Rain emitter rates
		if state == "Rain" then
			targetRainRate   = 200
			targetSplashRate = 60
		elseif state == "Storm" then
			targetRainRate   = 400
			targetSplashRate = 130
		else
			targetRainRate   = 0
			targetSplashRate = 0
		end
	end)
end

-- ── MAIN UPDATE LOOP ──────────────────────────────────────────────────────────
local function lerpColor(a, b, t)
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

RunService.Heartbeat:Connect(function(dt)
	local cc = STATE_CC[currentState] or STATE_CC.Clear
	local SPEED = dt * 0.8  -- slow blend speed

	weatherCC.Brightness = weatherCC.Brightness + (cc.brightness - weatherCC.Brightness) * SPEED
	weatherCC.Contrast   = weatherCC.Contrast   + (cc.contrast   - weatherCC.Contrast)   * SPEED
	weatherCC.Saturation = weatherCC.Saturation + (cc.saturation - weatherCC.Saturation) * SPEED
	weatherCC.TintColor  = lerpColor(weatherCC.TintColor, cc.tint, SPEED)

	-- Smooth rain emitter rates
	local blendRate = math.min(dt * 0.6, 1)
	rainEmitter.Rate   = rainEmitter.Rate   + (targetRainRate   - rainEmitter.Rate)   * blendRate
	splashEmitter.Rate = splashEmitter.Rate + (targetSplashRate - splashEmitter.Rate) * blendRate
end)

print("[WeatherClient] Initialized.")
