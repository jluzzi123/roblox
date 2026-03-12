return {
    ROOM_WIDTH  = 40,
    ROOM_HEIGHT = 12,
    ROOM_DEPTH  = 40,
    WALL_THICKNESS = 1,
    DOOR_WIDTH  = 8,
    DOOR_HEIGHT = 10,

    KEYS = {
        { id = "Key1", color = Color3.fromRGB(255, 200, 0),   label = "Gold Key"  },
        { id = "Key2", color = Color3.fromRGB(0,   200, 255), label = "Cyan Key"  },
    },
    -- Doors[i] is unlocked by KEYS[i]
    DOORS = {
        { id = "Door1", color = Color3.fromRGB(255, 200, 0)   },
        { id = "Door2", color = Color3.fromRGB(0,   200, 255) },
    },

    KEY_SIZE    = 2,
    KEY_FLOAT   = 3,
    BOB_SPEED   = 2,
    BOB_HEIGHT  = 0.5,
}
