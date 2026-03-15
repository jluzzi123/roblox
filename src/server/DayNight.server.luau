-- DayNight.server.luau
-- Smooth, continuous day/night cycle with time-of-day lighting interpolation.
-- Adjust CYCLE_MINUTES to control how fast the world day passes.

local Lighting    = game:GetService("Lighting")
local RunService  = game:GetService("RunService")

local CYCLE_MINUTES = 10     -- real-world minutes per full in-game day
local CYCLE_SECONDS = CYCLE_MINUTES * 60
local START_HOUR    = 9      -- starting clock hour (0–24)

-- ── MOON PHASE ────────────────────────────────────────────────────────────────
local MOON_CYCLE_SECONDS  = 8 * CYCLE_SECONDS   -- 8 in-game days = 80 real min
local MOON_MAX_BRIGHTNESS = 0.12                -- brightness boost at full moon midnight clear
local MOON_MAX_AMBIENT_R  = 15 / 255            -- moonlight color (cool blue-white)
local MOON_MAX_AMBIENT_G  = 18 / 255
local MOON_MAX_AMBIENT_B  = 25 / 255

-- ── TIME-OF-DAY PRESETS ───────────────────────────────────────────────────────
-- Each key is an in-game hour (0–23). Values are linearly interpolated between keys.
local PRESETS = {
	[0] = {  -- Midnight
		ambient     = Color3.fromRGB(24, 22, 42),
		outdoor     = Color3.fromRGB(30, 30, 58),
		brightness  = 0.12,
		fogColor    = Color3.fromRGB(12, 12, 30),
		fogEnd      = 480,
		atmDensity  = 0.60,
		sunRayInt   = 0.0,
		bloomInt    = 0.15,
		saturation  = -0.25,
		tint        = Color3.fromRGB(160, 170, 220),
	},
	[5] = {  -- Pre-dawn
		ambient     = Color3.fromRGB(28, 26, 44),
		outdoor     = Color3.fromRGB(42, 38, 68),
		brightness  = 0.20,
		fogColor    = Color3.fromRGB(32, 28, 52),
		fogEnd      = 650,
		atmDensity  = 0.52,
		sunRayInt   = 0.02,
		bloomInt    = 0.20,
		saturation  = -0.15,
		tint        = Color3.fromRGB(190, 185, 230),
	},
	[7] = {  -- Dawn / Sunrise
		ambient     = Color3.fromRGB(88, 64, 58),
		outdoor     = Color3.fromRGB(165, 108, 65),
		brightness  = 1.10,
		fogColor    = Color3.fromRGB(210, 148, 96),
		fogEnd      = 900,
		atmDensity  = 0.42,
		sunRayInt   = 0.38,
		bloomInt    = 0.55,
		saturation  = 0.08,
		tint        = Color3.fromRGB(255, 235, 210),
	},
	[10] = { -- Morning
		ambient     = Color3.fromRGB(92, 95, 102),
		outdoor     = Color3.fromRGB(136, 142, 154),
		brightness  = 2.20,
		fogColor    = Color3.fromRGB(182, 198, 218),
		fogEnd      = 1200,
		atmDensity  = 0.33,
		sunRayInt   = 0.22,
		bloomInt    = 0.38,
		saturation  = -0.03,
		tint        = Color3.fromRGB(240, 242, 255),
	},
	[13] = { -- Midday
		ambient     = Color3.fromRGB(98, 100, 108),
		outdoor     = Color3.fromRGB(145, 150, 162),
		brightness  = 2.55,
		fogColor    = Color3.fromRGB(192, 208, 228),
		fogEnd      = 1400,
		atmDensity  = 0.28,
		sunRayInt   = 0.18,
		bloomInt    = 0.35,
		saturation  = -0.02,
		tint        = Color3.fromRGB(245, 245, 255),
	},
	[16] = { -- Late afternoon
		ambient     = Color3.fromRGB(108, 90, 68),
		outdoor     = Color3.fromRGB(178, 148, 98),
		brightness  = 1.85,
		fogColor    = Color3.fromRGB(222, 188, 138),
		fogEnd      = 1050,
		atmDensity  = 0.36,
		sunRayInt   = 0.28,
		bloomInt    = 0.42,
		saturation  = 0.05,
		tint        = Color3.fromRGB(255, 240, 220),
	},
	[19] = { -- Sunset
		ambient     = Color3.fromRGB(92, 60, 46),
		outdoor     = Color3.fromRGB(162, 108, 72),
		brightness  = 1.05,
		fogColor    = Color3.fromRGB(210, 135, 80),
		fogEnd      = 820,
		atmDensity  = 0.46,
		sunRayInt   = 0.42,
		bloomInt    = 0.65,
		saturation  = 0.10,
		tint        = Color3.fromRGB(255, 228, 195),
	},
	[21] = { -- Dusk
		ambient     = Color3.fromRGB(32, 28, 48),
		outdoor     = Color3.fromRGB(50, 42, 78),
		brightness  = 0.28,
		fogColor    = Color3.fromRGB(28, 24, 52),
		fogEnd      = 580,
		atmDensity  = 0.54,
		sunRayInt   = 0.05,
		bloomInt    = 0.22,
		saturation  = -0.18,
		tint        = Color3.fromRGB(175, 175, 225),
	},
}

-- Build sorted hour list for interpolation
local sortedHours = {}
for h in pairs(PRESETS) do table.insert(sortedHours, h) end
table.sort(sortedHours)

-- ── HELPERS ───────────────────────────────────────────────────────────────────
local function lerpColor(a, b, t)
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function getPreset(hour)
	hour = hour % 24

	local prevH, nextH
	for i = #sortedHours, 1, -1 do
		if sortedHours[i] <= hour then
			prevH = sortedHours[i]
			nextH = sortedHours[i % #sortedHours + 1]
			break
		end
	end
	if not prevH then
		prevH = sortedHours[#sortedHours]
		nextH = sortedHours[1]
	end

	local p = PRESETS[prevH]
	local n = PRESETS[nextH]

	local span = (nextH - prevH) % 24
	if span == 0 then span = 24 end
	local t = math.clamp(((hour - prevH) % 24) / span, 0, 1)

	return {
		ambient     = lerpColor(p.ambient,    n.ambient,    t),
		outdoor     = lerpColor(p.outdoor,    n.outdoor,    t),
		brightness  = lerp(p.brightness,  n.brightness,  t),
		fogColor    = lerpColor(p.fogColor,   n.fogColor,   t),
		fogEnd      = lerp(p.fogEnd,      n.fogEnd,      t),
		atmDensity  = lerp(p.atmDensity,  n.atmDensity,  t),
		sunRayInt   = lerp(p.sunRayInt,   n.sunRayInt,   t),
		bloomInt    = lerp(p.bloomInt,    n.bloomInt,    t),
		saturation  = lerp(p.saturation,  n.saturation,  t),
		tint        = lerpColor(p.tint,       n.tint,       t),
	}
end

-- ── WAIT FOR ATMOSPHERE OBJECTS ───────────────────────────────────────────────
local atmosphere     = Lighting:WaitForChild("GameAtmosphere",     10)
local bloom          = Lighting:FindFirstChild("GameBloom")
local sunRays        = Lighting:FindFirstChild("GameSunRays")
local colorCorrect   = Lighting:FindFirstChild("GameColorCorrection")

-- ── WEATHER MULTIPLIERS ───────────────────────────────────────────────────────
-- Weather.server.luau writes to these via BindableEvent
local weatherBrightnessMult = 1.0
local weatherFogMult        = 1.0   -- < 1 = shorter fog (more obscured)
local weatherAtmAdd         = 0.0   -- extra atmosphere density from clouds/rain
local moonVisibility        = 1.0   -- written by weather event; 0=clouded, 1=clear sky

local weatherEvent = Instance.new("BindableEvent")
weatherEvent.Name   = "WeatherChanged"
weatherEvent.Parent = game:GetService("ReplicatedStorage")

weatherEvent.Event:Connect(function(data)
	weatherBrightnessMult = data.brightnessMult or 1.0
	weatherFogMult        = data.fogMult        or 1.0
	weatherAtmAdd         = data.atmAdd         or 0.0
	moonVisibility        = data.moonVisibility or 1.0
end)

-- ── MAIN LOOP ─────────────────────────────────────────────────────────────────
local elapsed = (START_HOUR / 24) * CYCLE_SECONDS
Lighting.ClockTime = START_HOUR

RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	local hour = ((elapsed % CYCLE_SECONDS) / CYCLE_SECONDS) * 24
	Lighting.ClockTime = hour

	-- Moon phase: 0=new moon, 1=full moon, sinusoidal over MOON_CYCLE_SECONDS
	local moonPhase   = (1 - math.cos((elapsed % MOON_CYCLE_SECONDS)
		/ MOON_CYCLE_SECONDS * 2 * math.pi)) * 0.5

	-- Night factor: 1.0 at midnight (hour=0), 0.0 at noon (hour=12)
	local nightFactor = (math.cos(hour / 24 * 2 * math.pi) + 1) * 0.5

	-- Combined moonlight multiplier
	local moonMult = moonPhase * nightFactor * moonVisibility

	local p = getPreset(hour)

	local moonBoostR = MOON_MAX_AMBIENT_R * moonMult
	local moonBoostG = MOON_MAX_AMBIENT_G * moonMult
	local moonBoostB = MOON_MAX_AMBIENT_B * moonMult

	Lighting.Ambient = Color3.new(
		math.clamp(p.ambient.R + moonBoostR, 0, 1),
		math.clamp(p.ambient.G + moonBoostG, 0, 1),
		math.clamp(p.ambient.B + moonBoostB, 0, 1)
	)
	Lighting.OutdoorAmbient = Color3.new(
		math.clamp(p.outdoor.R + moonBoostR, 0, 1),
		math.clamp(p.outdoor.G + moonBoostG, 0, 1),
		math.clamp(p.outdoor.B + moonBoostB, 0, 1)
	)
	Lighting.Brightness = p.brightness * weatherBrightnessMult
		+ MOON_MAX_BRIGHTNESS * moonMult
	Lighting.FogColor       = p.fogColor
	Lighting.FogEnd         = p.fogEnd * weatherFogMult

	if atmosphere then
		atmosphere.Density = math.clamp(p.atmDensity + weatherAtmAdd, 0, 1)
	end
	if sunRays then
		sunRays.Intensity = p.sunRayInt * weatherBrightnessMult
	end
	if bloom then
		bloom.Intensity = p.bloomInt
	end
	if colorCorrect then
		colorCorrect.Saturation = p.saturation
		colorCorrect.TintColor  = p.tint
	end
end)

print(string.format("[DayNight] Cycle started — %.1f min per day, starting at hour %d", CYCLE_MINUTES, START_HOUR))
