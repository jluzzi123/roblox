local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

-- RemoteEvents
local KeyCollected = Instance.new("RemoteEvent")
KeyCollected.Name = "KeyCollected"
KeyCollected.Parent = ReplicatedStorage

local GameWon = Instance.new("RemoteEvent")
GameWon.Name = "GameWon"
GameWon.Parent = ReplicatedStorage

-- World container
local escapeFolder = Instance.new("Folder")
escapeFolder.Name = "EscapeRoom"
escapeFolder.Parent = workspace

local W  = GameConfig.ROOM_WIDTH
local H  = GameConfig.ROOM_HEIGHT
local D  = GameConfig.ROOM_DEPTH
local WT = GameConfig.WALL_THICKNESS
local DW = GameConfig.DOOR_WIDTH
local DH = GameConfig.DOOR_HEIGHT

-- Room origins (bottom-center of each room at floor level y=0)
local ROOM_ORIGINS = {
    Vector3.new(-80, 0, 0),
    Vector3.new(  0, 0, 0),
    Vector3.new( 80, 0, 0),
}

local ROOM_COLORS = {
    Color3.fromRGB(180, 50,  50),  -- Room 1: red
    Color3.fromRGB(200, 170, 40),  -- Room 2: yellow
    Color3.fromRGB(50,  150, 70),  -- Room 3: green
}

local doors = {}      -- { [doorId] = Part }
local keyEntries = {} -- { part, baseY, phase, keyDef, collected }

local function makePart(parent, name, size, cframe, color, transparency, canCollide, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanCollide = canCollide ~= nil and canCollide or true
    p.Color = color
    p.Transparency = transparency or 0
    p.Material = material or Enum.Material.SmoothPlastic
    p.Parent = parent
    return p
end

-- Build a room. doorSide: "back" = +X wall has door, "front" = -X wall has door, nil = no door
local function buildRoom(origin, roomColor, frontDoorId, backDoorId)
    local ox, oy, oz = origin.X, origin.Y, origin.Z
    local cx = ox + W/2
    local cy = oy + H/2
    local cz = oz

    local folder = Instance.new("Folder")
    folder.Name = "Room"
    folder.Parent = escapeFolder

    -- Floor
    makePart(folder, "Floor", Vector3.new(W, WT, D),
        CFrame.new(cx, oy + WT/2, cz), roomColor)

    -- Ceiling
    makePart(folder, "Ceiling", Vector3.new(W, WT, D),
        CFrame.new(cx, oy + H + WT/2, cz), roomColor)

    -- Left wall (+Z side)
    makePart(folder, "WallLeft", Vector3.new(W, H, WT),
        CFrame.new(cx, cy, cz + D/2 + WT/2), roomColor)

    -- Right wall (-Z side)
    makePart(folder, "WallRight", Vector3.new(W, H, WT),
        CFrame.new(cx, cy, cz - D/2 - WT/2), roomColor)

    -- Front wall (-X side): may have door opening
    local frontX = ox - WT/2
    if frontDoorId then
        -- Two side pillars + lintel, leaving DW x DH gap centered
        local sideW = (W - DW) / 2
        -- Left pillar
        makePart(folder, "FrontL", Vector3.new(sideW, H, WT),
            CFrame.new(ox - WT/2, cy, cz + DW/2 + sideW/2), roomColor)
        -- Right pillar
        makePart(folder, "FrontR", Vector3.new(sideW, H, WT),
            CFrame.new(ox - WT/2, cy, cz - DW/2 - sideW/2), roomColor)
        -- Lintel
        local lintelH = H - DH
        makePart(folder, "FrontTop", Vector3.new(WT, lintelH, DW),
            CFrame.new(frontX, oy + DH + lintelH/2, cz), roomColor)
    else
        makePart(folder, "FrontWall", Vector3.new(WT, H, D),
            CFrame.new(frontX, cy, cz), roomColor)
    end

    -- Back wall (+X side): may have door opening
    local backX = ox + W + WT/2
    if backDoorId then
        local sideW = (W - DW) / 2
        makePart(folder, "BackL", Vector3.new(sideW, H, WT),
            CFrame.new(ox + W + WT/2, cy, cz + DW/2 + sideW/2), roomColor)
        makePart(folder, "BackR", Vector3.new(sideW, H, WT),
            CFrame.new(ox + W + WT/2, cy, cz - DW/2 - sideW/2), roomColor)
        local lintelH = H - DH
        makePart(folder, "BackTop", Vector3.new(WT, lintelH, DW),
            CFrame.new(backX, oy + DH + lintelH/2, cz), roomColor)
    else
        makePart(folder, "BackWall", Vector3.new(WT, H, D),
            CFrame.new(backX, cy, cz), roomColor)
    end
end

local function createDoor(doorDef, position)
    local p = Instance.new("Part")
    p.Name = doorDef.id
    p.Size = Vector3.new(WT + 0.1, DH, DW)
    p.CFrame = CFrame.new(position)
    p.Anchored = true
    p.CanCollide = true
    p.Color = doorDef.color
    p.Transparency = 0.3
    p.Material = Enum.Material.Neon
    p.CastShadow = false
    p.Parent = escapeFolder
    doors[doorDef.id] = p
end

local function createKey(keyDef, position)
    local p = Instance.new("Part")
    p.Name = keyDef.id
    p.Shape = Enum.PartType.Ball
    p.Size = Vector3.new(GameConfig.KEY_SIZE, GameConfig.KEY_SIZE, GameConfig.KEY_SIZE)
    p.Anchored = true
    p.CanCollide = false
    p.CastShadow = false
    p.Color = keyDef.color
    p.Material = Enum.Material.Neon
    p.Position = position
    p.Parent = escapeFolder

    table.insert(keyEntries, {
        part     = p,
        baseY    = position.Y,
        phase    = math.random() * 2 * math.pi,
        keyDef   = keyDef,
        collected = false,
    })
end

local function buildWorld()
    -- Night lighting
    local Lighting = game:GetService("Lighting")
    Lighting.ClockTime      = 0
    Lighting.Brightness     = 0.3
    Lighting.Ambient        = Color3.fromRGB(10, 10, 25)
    Lighting.OutdoorAmbient = Color3.fromRGB(10, 10, 25)
    Lighting.FogEnd         = 300
    Lighting.FogColor       = Color3.fromRGB(15, 15, 30)

    local atmo = Instance.new("Atmosphere")
    atmo.Density  = 0.4
    atmo.Offset   = 0.1
    atmo.Color    = Color3.fromRGB(100, 110, 140)
    atmo.Glare    = 0
    atmo.Haze     = 2
    atmo.Parent   = Lighting

    -- Rain emitter
    local rainPart = Instance.new("Part")
    rainPart.Name        = "RainEmitter"
    rainPart.Size        = Vector3.new(600, 1, 600)
    rainPart.Position    = Vector3.new(0, 120, 0)
    rainPart.Anchored    = true
    rainPart.CanCollide  = false
    rainPart.Transparency = 1
    rainPart.Parent      = workspace

    local rain = Instance.new("ParticleEmitter")
    rain.Texture           = "rbxasset://textures/particles/rain_main.dds"
    rain.Rate              = 600
    rain.Lifetime          = NumberRange.new(1.5, 2.5)
    rain.Speed             = NumberRange.new(80, 100)
    rain.EmissionDirection = Enum.NormalId.Bottom
    rain.SpreadAngle       = Vector2.new(0, 0)
    rain.Size              = NumberSequence.new(0.06)
    rain.Transparency      = NumberSequence.new(0.2)
    rain.Color             = ColorSequence.new(Color3.fromRGB(150, 180, 220))
    rain.LightEmission     = 0.1
    rain.Parent            = rainPart

    -- Room 1: no front door, Door1 on back wall
    buildRoom(ROOM_ORIGINS[1], ROOM_COLORS[1], nil, "Door1")
    -- Room 2: Door1 on front wall, Door2 on back wall
    buildRoom(ROOM_ORIGINS[2], ROOM_COLORS[2], "Door1", "Door2")
    -- Room 3: Door2 on front wall, no back door
    buildRoom(ROOM_ORIGINS[3], ROOM_COLORS[3], "Door2", nil)

    -- Door1: between Room1 and Room2 (at x = -80 + 40 = -40)
    createDoor(GameConfig.DOORS[1], Vector3.new(-40, DH/2, 0))
    -- Door2: between Room2 and Room3 (at x = 0 + 40 = 40)
    createDoor(GameConfig.DOORS[2], Vector3.new(40, DH/2, 0))

    -- Key1 in Room1 center
    createKey(GameConfig.KEYS[1], Vector3.new(-60, GameConfig.KEY_FLOAT, 0))
    -- Key2 in Room2 center
    createKey(GameConfig.KEYS[2], Vector3.new(20, GameConfig.KEY_FLOAT, 0))

    -- Win trigger: fills Room3 (invisible)
    local trigger = Instance.new("Part")
    trigger.Name = "WinTrigger"
    trigger.Size = Vector3.new(W - 2, H - 2, D - 2)
    trigger.CFrame = CFrame.new(80 + W/2, H/2, 0)
    trigger.Anchored = true
    trigger.CanCollide = false
    trigger.Transparency = 1
    trigger.Parent = escapeFolder

    trigger.Touched:Connect(function(hit)
        local character = hit.Parent
        local player = Players:GetPlayerFromCharacter(character)
        if not player then return end
        -- Only fire once per player
        local won = player:FindFirstChild("HasWon")
        if won then return end
        local flag = Instance.new("BoolValue")
        flag.Name = "HasWon"
        flag.Parent = player
        GameWon:FireClient(player)
    end)
end

local function unlockDoor(doorId)
    local door = doors[doorId]
    if door then
        door.Transparency = 1
        door.CanCollide = false
    end
end

local function setupKeyTouches()
    for _, entry in ipairs(keyEntries) do
        local e = entry
        e.part.Touched:Connect(function(hit)
            if e.collected then return end
            local character = hit.Parent
            local player = Players:GetPlayerFromCharacter(character)
            if not player then return end

            e.collected = true
            e.part:Destroy()

            -- Record on player
            local val = Instance.new("StringValue")
            val.Name = e.keyDef.id
            val.Value = "collected"
            val.Parent = player

            -- Find matching door index
            for i, kd in ipairs(GameConfig.KEYS) do
                if kd.id == e.keyDef.id then
                    local doorDef = GameConfig.DOORS[i]
                    if doorDef then
                        unlockDoor(doorDef.id)
                    end
                    break
                end
            end

            KeyCollected:FireClient(player, { label = e.keyDef.label, keyId = e.keyDef.id })
        end)
    end
end

-- Bob animation
RunService.Heartbeat:Connect(function()
    local t = tick()
    for _, entry in ipairs(keyEntries) do
        if not entry.collected and entry.part and entry.part.Parent then
            local yOffset = math.sin(t * GameConfig.BOB_SPEED + entry.phase) * GameConfig.BOB_HEIGHT
            entry.part.Position = Vector3.new(
                entry.part.Position.X,
                entry.baseY + yOffset,
                entry.part.Position.Z
            )
        end
    end
end)

buildWorld()
setupKeyTouches()
