# Roblox Studio - Getting Started

## Key Concepts
- **ServerScript** - runs on the server, handles game logic (put in ServerScriptService)
- **LocalScript** - runs on the player's device, handles UI and input (put in StarterPlayerScripts)
- **ModuleScript** - reusable code you can require from other scripts

## Lua Basics
```lua
-- Print to output
print("Hello Roblox!")

-- Variables
local myName = "Player"
local myNumber = 10

-- Functions
local function greet(name)
    print("Hello, " .. name)
end

greet(myName)

-- If statements
if myNumber > 5 then
    print("Big number")
else
    print("Small number")
end

-- Loops
for i = 1, 10 do
    print(i)
end
```

## Common Roblox Objects
- `game.Workspace` - everything in the 3D world
- `game.Players` - all players in the game
- `game.ReplicatedStorage` - shared storage between server and client

## First Steps in Studio
1. Open Roblox Studio → New Baseplate
2. Open Explorer panel (View > Explorer)
3. Open Output panel (View > Output)
4. Add a Script to ServerScriptService and test with print()
