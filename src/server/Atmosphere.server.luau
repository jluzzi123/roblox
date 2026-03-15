-- Atmosphere.server.luau
-- Creates and configures all visual atmosphere objects in Lighting.
-- DayNight and Weather scripts will find these by name and adjust them at runtime.

local Lighting = game:GetService("Lighting")

-- ── ATMOSPHERE OBJECT (haze, scatter, fog color) ─────────────────────────────
local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "GameAtmosphere"
atmosphere.Density    = 0.35
atmosphere.Offset     = 0.22
atmosphere.Color      = Color3.fromRGB(199, 210, 230)
atmosphere.Decay      = Color3.fromRGB(100, 100, 128)
atmosphere.Glare      = 0.30
atmosphere.Haze       = 1.6
atmosphere.Parent     = Lighting

-- ── BLOOM ─────────────────────────────────────────────────────────────────────
local bloom = Instance.new("BloomEffect")
bloom.Name      = "GameBloom"
bloom.Intensity = 0.35
bloom.Size      = 22
bloom.Threshold = 0.96
bloom.Parent    = Lighting

-- ── COLOR CORRECTION ──────────────────────────────────────────────────────────
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Name       = "GameColorCorrection"
colorCorrection.Brightness = -0.02
colorCorrection.Contrast   = 0.06
colorCorrection.Saturation = -0.04
colorCorrection.TintColor  = Color3.fromRGB(240, 242, 255)
colorCorrection.Parent     = Lighting

-- ── SUN RAYS ──────────────────────────────────────────────────────────────────
local sunRays = Instance.new("SunRaysEffect")
sunRays.Name      = "GameSunRays"
sunRays.Intensity = 0.20
sunRays.Spread    = 0.45
sunRays.Parent    = Lighting

-- ── CLOUDS ────────────────────────────────────────────────────────────────────
-- Clouds must be parented to workspace.Terrain in Roblox
local terrain = workspace:WaitForChild("Terrain")
local clouds = terrain:FindFirstChildOfClass("Clouds")
if not clouds then
	clouds = Instance.new("Clouds")
	clouds.Parent = terrain
end
clouds.Name    = "GameClouds"
clouds.Cover   = 0.42
clouds.Density = 0.65
clouds.Color   = Color3.fromRGB(218, 224, 236)

-- ── LIGHTING BASE SETTINGS ────────────────────────────────────────────────────
-- DayNight.server.luau will override these each frame, but set sane defaults
Lighting.ClockTime          = 10
Lighting.GeographicLatitude = 45
Lighting.Brightness         = 2.2
Lighting.Ambient            = Color3.fromRGB(90, 92, 102)
Lighting.OutdoorAmbient     = Color3.fromRGB(130, 135, 148)
Lighting.FogColor           = Color3.fromRGB(182, 198, 218)
Lighting.FogStart           = 80
Lighting.FogEnd             = 1200
Lighting.ShadowSoftness     = 0.30
Lighting.ColorShift_Top     = Color3.fromRGB(255, 244, 228)
Lighting.ColorShift_Bottom  = Color3.fromRGB(75, 88, 118)
Lighting.GlobalShadows      = true

print("[Atmosphere] Visual objects created and configured.")
