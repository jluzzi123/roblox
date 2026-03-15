-- CompassHUD.client.luau
-- Ribbon compass at top-center showing N/NE/E/SE/S/SW/W/NW relative to camera facing.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

-- ── BUILD GUI ──────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "CompassHUD"
screenGui.ResetOnSpawn    = false
screenGui.IgnoreGuiInset  = true
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling

local bar = Instance.new("Frame", screenGui)
bar.Name                   = "CompassBar"
bar.AnchorPoint            = Vector2.new(0.5, 0)
bar.Position               = UDim2.new(0.5, 0, 0, 16)
bar.Size                   = UDim2.new(0, 280, 0, 36)
bar.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
bar.BackgroundTransparency = 0.35
bar.BorderSizePixel        = 0
bar.ClipsDescendants       = true

local corner = Instance.new("UICorner", bar)
corner.CornerRadius = UDim.new(0, 8)

-- Gold center tick — fixed, marks current heading
local centerTick = Instance.new("Frame", bar)
centerTick.Name                   = "CenterTick"
centerTick.AnchorPoint            = Vector2.new(0.5, 0.5)
centerTick.Position               = UDim2.new(0.5, 0, 0.5, 0)
centerTick.Size                   = UDim2.new(0, 2, 0, 14)
centerTick.BackgroundColor3       = Color3.fromRGB(255, 215, 80)
centerTick.BackgroundTransparency = 0
centerTick.BorderSizePixel        = 0

-- Direction labels
local DIRECTIONS = {
	{ text = "N",  angle = 0,   major = true  },
	{ text = "NE", angle = 45,  major = false },
	{ text = "E",  angle = 90,  major = true  },
	{ text = "SE", angle = 135, major = false },
	{ text = "S",  angle = 180, major = true  },
	{ text = "SW", angle = 225, major = false },
	{ text = "W",  angle = 270, major = true  },
	{ text = "NW", angle = 315, major = false },
}

for _, dir in ipairs(DIRECTIONS) do
	local lbl = Instance.new("TextLabel", bar)
	lbl.Name                   = dir.text
	lbl.Size                   = UDim2.new(0, 28, 1, 0)
	lbl.AnchorPoint            = Vector2.new(0.5, 0)
	lbl.Position               = UDim2.new(0, 0, 0, 0)   -- updated each frame
	lbl.BackgroundTransparency = 1
	lbl.TextColor3             = dir.major
		and Color3.fromRGB(255, 255, 255)
		or  Color3.fromRGB(175, 175, 175)
	lbl.Font                   = dir.major and Enum.Font.GothamBold or Enum.Font.GothamMedium
	lbl.TextSize               = dir.major and 14 or 11
	lbl.TextXAlignment         = Enum.TextXAlignment.Center
	lbl.TextYAlignment         = Enum.TextYAlignment.Center
	lbl.TextStrokeTransparency = 0.6
	lbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
	lbl.Text                   = dir.text
	dir.labelInstance          = lbl
end

screenGui.Parent = playerGui

-- ── UPDATE LOOP ────────────────────────────────────────────────────────────────
local PIXELS_PER_DEGREE = 1.8
local BAR_CENTER_X = 140   -- half of 280px bar width

RunService.Heartbeat:Connect(function()
	local look = camera.CFrame.LookVector
	local yaw = math.deg(math.atan2(look.X, -look.Z)) % 360

	for _, dir in ipairs(DIRECTIONS) do
		local delta = ((dir.angle - yaw + 180) % 360) - 180
		local xPixel = BAR_CENTER_X + delta * PIXELS_PER_DEGREE
		dir.labelInstance.Position = UDim2.new(0, xPixel, 0, 0)
	end
end)

print("[CompassHUD] Initialized.")
