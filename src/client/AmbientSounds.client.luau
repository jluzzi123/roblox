-- AmbientSounds.client.luau
-- Layered ambient audio: day sounds fade into night sounds based on ClockTime.
-- Weather state from WeatherState RemoteEvent triggers rain/storm audio.
--
-- NOTE: Replace the asset IDs below with your preferred Roblox audio assets.
-- Find free ambient sounds at: create.roblox.com/store (search "ambient", "birds", etc.)

local Lighting          = game:GetService("Lighting")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")

-- ── SOUND ASSET IDs ───────────────────────────────────────────────────────────
-- Replace these with verified Roblox free audio asset IDs:
local ASSETS = {
	birds    = "rbxassetid://105990653889537",  -- forest birds / daytime ambience
	wind     = "rbxassetid://9118747853",        -- gentle breeze
	crickets = "rbxassetid://124263261633399",  -- night crickets
	owl      = "rbxassetid://133901775721002",  -- distant owl call
	rain     = "rbxassetid://9112853563",        -- steady rainfall
	thunder  = "rbxassetid://139319051979882",  -- distant thunder rumble
}

-- ── SOUND SETUP ───────────────────────────────────────────────────────────────
local ambientFolder = Instance.new("Folder")
ambientFolder.Name   = "AmbientSounds"
ambientFolder.Parent = SoundService  -- parented to SoundService so they're not 3D positioned

local function makeSound(assetId, volume, looped, name)
	local s = Instance.new("Sound")
	s.Name         = name or assetId
	s.SoundId      = assetId
	s.Volume       = 0
	s.Looped       = looped
	s.RollOffMaxDistance = 0  -- no rolloff for ambient sounds
	s.Parent       = ambientFolder
	s:Play()
	return s
end

local sBirds    = makeSound(ASSETS.birds,    0.55, true,  "Birds")
local sWind     = makeSound(ASSETS.wind,     0.30, true,  "Wind")
local sCrickets = makeSound(ASSETS.crickets, 0.65, true,  "Crickets")
local sOwl      = makeSound(ASSETS.owl,      0.0,  false, "Owl")
local sRain     = makeSound(ASSETS.rain,     0.0,  true,  "Rain")
local sThunder  = makeSound(ASSETS.thunder,  0.0,  true,  "Thunder")

-- ── VOLUME TARGETS ────────────────────────────────────────────────────────────
-- Current target volumes (smoothly applied each frame)
local targets = {
	Birds    = 0,
	Wind     = 0,
	Crickets = 0,
	Rain     = 0,
	Thunder  = 0,
}

-- ── SMOOTH LERP HELPER ────────────────────────────────────────────────────────
local function smoothStep(current, target, dt, speed)
	return current + (target - current) * math.min(dt * speed, 1)
end

-- ── WEATHER STATE ─────────────────────────────────────────────────────────────
local weatherState = "Clear"  -- updated by RemoteEvent

local weatherRemote = ReplicatedStorage:WaitForChild("WeatherState", 15)
if weatherRemote then
	weatherRemote.OnClientEvent:Connect(function(state)
		if state ~= "Lightning" then  -- Lightning is a one-shot event, not a state
			weatherState = state
		end
	end)
end

-- ── OWL PERIODIC CALL ─────────────────────────────────────────────────────────
local nextOwlTime = tick() + math.random(30, 90)

-- ── MAIN UPDATE LOOP ──────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function(dt)
	local hour = Lighting.ClockTime

	-- Day fraction: 1 = full day, 0 = full night
	-- Day: hour 7–19, Night: hour 20–6
	local dayBlend
	if hour >= 7 and hour <= 19 then
		-- Peak day at hour 13, blend up from 7, down toward 19
		dayBlend = math.clamp((math.sin((hour - 7) / 12 * math.pi)), 0, 1)
	else
		dayBlend = 0
	end
	local nightBlend = 1 - dayBlend

	-- Weather modifiers
	local isRain  = weatherState == "Rain"  or weatherState == "Storm"
	local isStorm = weatherState == "Storm"
	local rainMult  = isRain  and 1 or 0
	local stormMult = isStorm and 1 or 0

	-- Compute target volumes
	-- During rain, suppress birds (they go quiet in rain)
	local rainSuppression = isRain and 0.15 or 1.0

	targets.Birds    = 0.50 * dayBlend   * rainSuppression
	targets.Wind     = 0.28 * (0.4 + 0.6 * (weatherState == "Clear" and 0 or 1))
	targets.Crickets = 0.60 * nightBlend * (isStorm and 0.1 or 1.0)
	targets.Rain     = 0.70 * rainMult
	targets.Thunder  = 0.35 * stormMult

	-- Apply smoothed volumes (speed = 1.5 units/sec for slow crossfade)
	local FADE_SPEED = 1.5
	sBirds.Volume    = smoothStep(sBirds.Volume,    targets.Birds,    dt, FADE_SPEED)
	sWind.Volume     = smoothStep(sWind.Volume,     targets.Wind,     dt, FADE_SPEED)
	sCrickets.Volume = smoothStep(sCrickets.Volume, targets.Crickets, dt, FADE_SPEED)
	sRain.Volume     = smoothStep(sRain.Volume,     targets.Rain,     dt, FADE_SPEED)
	sThunder.Volume  = smoothStep(sThunder.Volume,  targets.Thunder,  dt, FADE_SPEED)

	-- Occasional owl call at night
	if nightBlend > 0.7 and not isStorm and tick() >= nextOwlTime then
		sOwl.Volume = 0.40 * nightBlend
		sOwl:Play()
		nextOwlTime = tick() + math.random(45, 120)
	end
end)

print("[AmbientSounds] Initialized.")
