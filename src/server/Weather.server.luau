-- Weather.server.luau
-- Cycles through weather states: Clear → Overcast → Rain → Storm → Clear
-- Fires RemoteEvents to clients for rain particles and screen effects.
-- Writes weather data to BindableEvent so DayNight can adjust lighting.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")

-- ── REMOTE EVENT (server → clients) ──────────────────────────────────────────
local weatherRemote = Instance.new("RemoteEvent")
weatherRemote.Name   = "WeatherState"
weatherRemote.Parent = ReplicatedStorage

-- ── BINDABLE EVENT (server → DayNight script) ─────────────────────────────────
-- Wait for DayNight to create it first (both are in ServerScriptService so order varies)
local weatherBindable = ReplicatedStorage:WaitForChild("WeatherChanged", 15)

-- ── CLOUDS REFERENCE ──────────────────────────────────────────────────────────
local terrain = workspace:WaitForChild("Terrain")
local clouds  = terrain:WaitForChild("GameClouds", 10)

-- ── WEATHER STATE DEFINITIONS ─────────────────────────────────────────────────
-- minDuration / maxDuration in real seconds
local STATES = {
	Clear = {
		minDuration     = 90,
		maxDuration     = 180,
		cloudCover      = 0.22,
		cloudDensity    = 0.55,
		brightnessMult  = 1.00,
		fogMult         = 1.00,
		atmAdd          = 0.00,
		moonVisibility  = 1.00,
		next            = "Overcast",
	},
	Overcast = {
		minDuration     = 60,
		maxDuration     = 120,
		cloudCover      = 0.75,
		cloudDensity    = 0.85,
		brightnessMult  = 0.70,
		fogMult         = 0.75,
		atmAdd          = 0.12,
		moonVisibility  = 0.35,
		next            = "Rain",
	},
	Rain = {
		minDuration     = 60,
		maxDuration     = 150,
		cloudCover      = 0.92,
		cloudDensity    = 0.95,
		brightnessMult  = 0.50,
		fogMult         = 0.55,
		atmAdd          = 0.25,
		moonVisibility  = 0.12,
		next            = "Storm",
	},
	Storm = {
		minDuration     = 30,
		maxDuration     = 75,
		cloudCover      = 1.00,
		cloudDensity    = 1.00,
		brightnessMult  = 0.35,
		fogMult         = 0.40,
		atmAdd          = 0.35,
		moonVisibility  = 0.04,
		next            = "Clear",
	},
}

-- ── TRANSITION HELPERS ────────────────────────────────────────────────────────
local TRANSITION_DURATION = 12  -- seconds to blend between states

local function lerpNumber(a, b, t) return a + (b - a) * t end

local function transitionTo(fromState, toState, t)
	local f = STATES[fromState]
	local g = STATES[toState]
	if not f or not g then return end

	local cover   = lerpNumber(f.cloudCover,     g.cloudCover,     t)
	local density = lerpNumber(f.cloudDensity,   g.cloudDensity,   t)
	local bMult   = lerpNumber(f.brightnessMult, g.brightnessMult, t)
	local fMult   = lerpNumber(f.fogMult,        g.fogMult,        t)
	local aAdd    = lerpNumber(f.atmAdd,          g.atmAdd,         t)
	local moonVis = lerpNumber(f.moonVisibility,  g.moonVisibility, t)

	if clouds then
		clouds.Cover   = cover
		clouds.Density = density
	end

	if weatherBindable then
		weatherBindable:Fire({
			brightnessMult = bMult,
			fogMult        = fMult,
			atmAdd         = aAdd,
			moonVisibility = moonVis,
		})
	end
end

-- ── LIGHTNING FLASH ───────────────────────────────────────────────────────────
local function doLightningFlash()
	local origBrightness = Lighting.Brightness
	-- Quick flash sequence
	for _, mult in ipairs({ 6, 2, 8, 1.5 }) do
		Lighting.Brightness = origBrightness * mult
		task.wait(0.04)
		Lighting.Brightness = origBrightness
		task.wait(0.06)
	end
end

-- ── MAIN STATE MACHINE ────────────────────────────────────────────────────────
local currentState = "Clear"

local function applyState(stateName)
	local s = STATES[stateName]
	if not s then return end

	if clouds then
		clouds.Cover   = s.cloudCover
		clouds.Density = s.cloudDensity
	end
	if weatherBindable then
		weatherBindable:Fire({
			brightnessMult = s.brightnessMult,
			fogMult        = s.fogMult,
			atmAdd         = s.atmAdd,
			moonVisibility = s.moonVisibility,
		})
	end

	-- Tell all clients the new weather state
	weatherRemote:FireAllClients(stateName)
	print(string.format("[Weather] State → %s", stateName))
end

local function runWeatherCycle()
	-- Apply initial state immediately
	applyState(currentState)

	while true do
		local s = STATES[currentState]
		local duration = math.random(s.minDuration, s.maxDuration)
		local nextState = s.next

		-- Storm: periodically fire lightning
		if currentState == "Storm" then
			local stormEnd = tick() + duration
			while tick() < stormEnd do
				task.wait(math.random(8, 20))
				if tick() < stormEnd then
					doLightningFlash()
					weatherRemote:FireAllClients("Lightning")
				end
			end
		else
			task.wait(duration)
		end

		-- Smooth transition to next state
		print(string.format("[Weather] Transitioning %s → %s", currentState, nextState))
		local fromState = currentState

		local steps = 60
		for i = 1, steps do
			local t = i / steps
			transitionTo(fromState, nextState, t)
			-- Also notify clients of intermediate state for smooth rain fade
			if i == steps // 2 then
				weatherRemote:FireAllClients(nextState)
			end
			task.wait(TRANSITION_DURATION / steps)
		end

		currentState = nextState
		applyState(currentState)
	end
end

-- Start after a short delay so Atmosphere script has time to set up clouds
task.delay(2, function()
	local ok, err = pcall(runWeatherCycle)
	if not ok then
		warn("[Weather] Cycle error: " .. tostring(err))
	end
end)

print("[Weather] Initialized. Starting with Clear weather.")
