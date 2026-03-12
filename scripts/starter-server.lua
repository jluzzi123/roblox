-- StarterServerScript
-- Place this in ServerScriptService in Roblox Studio

local Players = game:GetService("Players")

-- Runs when a player joins
Players.PlayerAdded:Connect(function(player)
    print(player.Name .. " joined the game!")
end)

-- Runs when a player leaves
Players.PlayerRemoving:Connect(function(player)
    print(player.Name .. " left the game.")
end)
