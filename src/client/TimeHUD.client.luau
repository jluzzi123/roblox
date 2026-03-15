-- TimeHUD.client.luau
-- Displays the current in-game time and weather state in the bottom-right corner.
-- Lighting.ClockTime is replicated automatically — no server changes needed.

local Lighting          = game:GetService("Lighting")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── WEATHER TABLE ──────────────────────────────────────────────────────────────
local WEATHER = {
	Clear    = { name = "Clear",    icon = "○" },
	Overcast = { name = "Overcast", icon = "~" },
	Rain     = { name = "Rain",     icon = "\u{2248}" },
	Storm    = { name = "Storm",    icon = "\u{26A1}" },
}
local currentWeather = WEATHER.Clear

local weatherEvent = ReplicatedStorage:WaitForChild("WeatherState")
weatherEvent.OnClientEvent:Connect(function(stateName)
	if WEATHER[stateName] then  -- filters out "Lightning"
		currentWeather = WEATHER[stateName]
	end
end)

local function formatTime(clockTime)
	local totalMinutes = math.floor(clockTime * 60)
	local hours        = math.floor(totalMinutes / 60) % 24
	local minutes      = totalMinutes % 60
	local suffix       = hours >= 12 and "PM" or "AM"
	local hour12       = hours % 12
	if hour12 == 0 then hour12 = 12 end
	return string.format("%d:%02d %s", hour12, minutes, suffix)
end

-- ── BUILD GUI ─────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "TimeHUD"
screenGui.ResetOnSpawn    = false
screenGui.IgnoreGuiInset  = true
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling

local frame = Instance.new("Frame", screenGui)
frame.Name            = "TimeFrame"
frame.AnchorPoint     = Vector2.new(1, 1)
frame.Position        = UDim2.new(1, -16, 1, -16)
frame.Size            = UDim2.new(0, 160, 0, 60)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.35
frame.BorderSizePixel = 0

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 8)

local padding = Instance.new("UIPadding", frame)
padding.PaddingLeft   = UDim.new(0, 10)
padding.PaddingRight  = UDim.new(0, 10)
padding.PaddingTop    = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)

local timeLabel = Instance.new("TextLabel", frame)
timeLabel.Name                   = "TimeLabel"
timeLabel.AnchorPoint            = Vector2.new(0, 0)
timeLabel.Position               = UDim2.new(0, 0, 0, 0)
timeLabel.Size                   = UDim2.new(1, 0, 0.5, 0)
timeLabel.BackgroundTransparency = 1
timeLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
timeLabel.TextStrokeTransparency = 0.6
timeLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
timeLabel.Font                   = Enum.Font.GothamBold
timeLabel.TextSize               = 14
timeLabel.TextXAlignment         = Enum.TextXAlignment.Center
timeLabel.TextYAlignment         = Enum.TextYAlignment.Center
timeLabel.Text                   = ""

local weatherLabel = Instance.new("TextLabel", frame)
weatherLabel.Name                   = "WeatherLabel"
weatherLabel.AnchorPoint            = Vector2.new(0, 1)
weatherLabel.Position               = UDim2.new(0, 0, 1, 0)
weatherLabel.Size                   = UDim2.new(1, 0, 0.5, 0)
weatherLabel.BackgroundTransparency = 1
weatherLabel.TextColor3             = Color3.fromRGB(220, 220, 220)
weatherLabel.TextStrokeTransparency = 0.6
weatherLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
weatherLabel.Font                   = Enum.Font.GothamMedium
weatherLabel.TextSize               = 13
weatherLabel.TextXAlignment         = Enum.TextXAlignment.Center
weatherLabel.TextYAlignment         = Enum.TextYAlignment.Center
weatherLabel.Text                   = ""

screenGui.Parent = playerGui

-- ── UPDATE LOOP ───────────────────────────────────────────────────────────────
local UPDATE_INTERVAL = 1  -- seconds between HUD refreshes
local timeSinceUpdate = UPDATE_INTERVAL  -- trigger an immediate update on first frame

RunService.Heartbeat:Connect(function(dt)
	timeSinceUpdate += dt
	if timeSinceUpdate < UPDATE_INTERVAL then return end
	timeSinceUpdate = 0

	timeLabel.Text    = formatTime(Lighting.ClockTime)
	weatherLabel.Text = currentWeather.icon .. "  " .. currentWeather.name
end)
