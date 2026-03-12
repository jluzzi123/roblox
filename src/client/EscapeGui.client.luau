local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local KeyCollected = ReplicatedStorage:WaitForChild("KeyCollected")
local GameWon      = ReplicatedStorage:WaitForChild("GameWon")

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EscapeGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- HUD: key inventory (top-left)
local hudLabel = Instance.new("TextLabel")
hudLabel.Name = "HUD"
hudLabel.Size = UDim2.new(0, 240, 0, 50)
hudLabel.Position = UDim2.new(0, 20, 0, 20)
hudLabel.BackgroundColor3 = Color3.new(0, 0, 0)
hudLabel.BackgroundTransparency = 0.4
hudLabel.TextColor3 = Color3.new(1, 1, 1)
hudLabel.TextScaled = true
hudLabel.Font = Enum.Font.GothamBold
hudLabel.Text = "Keys: none"
hudLabel.Parent = screenGui

local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 8)
hudCorner.Parent = hudLabel

-- Notification label (center, fades out)
local notifLabel = Instance.new("TextLabel")
notifLabel.Name = "Notif"
notifLabel.Size = UDim2.new(0.6, 0, 0, 60)
notifLabel.Position = UDim2.new(0.2, 0, 0.4, 0)
notifLabel.AnchorPoint = Vector2.new(0, 0)
notifLabel.BackgroundColor3 = Color3.new(0, 0, 0)
notifLabel.BackgroundTransparency = 0.3
notifLabel.TextColor3 = Color3.new(1, 0.9, 0.2)
notifLabel.TextScaled = true
notifLabel.Font = Enum.Font.GothamBold
notifLabel.Text = ""
notifLabel.Visible = false
notifLabel.ZIndex = 5
notifLabel.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 10)
notifCorner.Parent = notifLabel

-- Win overlay (hidden initially)
local winFrame = Instance.new("Frame")
winFrame.Name = "WinFrame"
winFrame.Size = UDim2.new(1, 0, 1, 0)
winFrame.BackgroundColor3 = Color3.new(0, 0, 0)
winFrame.BackgroundTransparency = 0.3
winFrame.Visible = false
winFrame.ZIndex = 10
winFrame.Parent = screenGui

local winLabel = Instance.new("TextLabel")
winLabel.Size = UDim2.new(0.6, 0, 0.3, 0)
winLabel.Position = UDim2.new(0.2, 0, 0.35, 0)
winLabel.BackgroundTransparency = 1
winLabel.TextColor3 = Color3.new(0.3, 1, 0.4)
winLabel.TextScaled = true
winLabel.Font = Enum.Font.GothamBold
winLabel.Text = "YOU ESCAPED! 🎉"
winLabel.ZIndex = 11
winLabel.Parent = winFrame

-- Track collected keys for HUD
local collectedLabels = {}

local notifTween = nil

local function showNotif(text)
    if notifTween then notifTween:Cancel() end
    notifLabel.Text = text
    notifLabel.TextTransparency = 0
    notifLabel.BackgroundTransparency = 0.3
    notifLabel.Visible = true

    notifTween = TweenService:Create(notifLabel,
        TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
        { TextTransparency = 1, BackgroundTransparency = 1 }
    )
    notifTween:Play()
    notifTween.Completed:Connect(function()
        notifLabel.Visible = false
    end)
end

KeyCollected.OnClientEvent:Connect(function(data)
    table.insert(collectedLabels, data.label)
    hudLabel.Text = "Keys: " .. table.concat(collectedLabels, ", ")
    showNotif("You found the " .. data.label .. "! A door unlocked.")
end)

GameWon.OnClientEvent:Connect(function()
    winFrame.Visible = true
end)
