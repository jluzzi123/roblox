-- PlaceFlowers.lua — Sparse wildflower patches scattered across the map
-- Paste into Studio Command Bar. Takes ~30 seconds.

local SEED     = 77
local MAP_SIZE = 4800
local rng      = Random.new(SEED)
local half     = MAP_SIZE / 2

-- Clear old flowers
local old = workspace:FindFirstChild("Flowers")
if old then old:Destroy() end
local fFolder = Instance.new("Folder"); fFolder.Name = "Flowers"; fFolder.Parent = workspace

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = {workspace.Terrain}

local function getY(x, z)
	local hit = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), params)
	return hit and hit.Position.Y or nil
end

-- ── FLOWER COLOR PALETTES ────────────────────────────────────────────────────
-- Each palette: { head color, center/accent color }
-- Patches are mono-color so clusters look intentional
local PALETTES = {
	{ Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 215, 40)  },  -- white daisy
	{ Color3.fromRGB(185, 100, 225), Color3.fromRGB(255, 215, 40)  },  -- purple wildflower
	{ Color3.fromRGB(255, 210, 55),  Color3.fromRGB(255, 210, 55)  },  -- yellow buttercup
	{ Color3.fromRGB(255, 130, 175), Color3.fromRGB(255, 255, 255) },  -- pink blossom
	{ Color3.fromRGB(100, 155, 255), Color3.fromRGB(255, 255, 255) },  -- blue forget-me-not
	{ Color3.fromRGB(255, 75,  75),  Color3.fromRGB(255, 215, 40)  },  -- red poppy
}

local STEM_COLOR = Color3.fromRGB(55, 105, 35)

-- ── SINGLE FLOWER ────────────────────────────────────────────────────────────
local function makeFlower(parent, x, y, z, palette)
	local stemH = rng:NextNumber(0.28, 0.58)
	local headR = rng:NextNumber(0.14, 0.32)

	-- Stem
	local stem = Instance.new("Part")
	stem.Shape      = Enum.PartType.Cylinder
	stem.Size       = Vector3.new(stemH, 0.055, 0.055)
	stem.CFrame     = CFrame.new(x, y + stemH / 2, z) * CFrame.Angles(0, 0, math.rad(90))
	stem.Anchored   = true
	stem.CanCollide = false
	stem.Color      = STEM_COLOR
	stem.Material   = Enum.Material.SmoothPlastic
	stem.CastShadow = false
	stem.Parent     = parent

	-- Flower head
	local head = Instance.new("Part")
	head.Shape      = Enum.PartType.Ball
	head.Size       = Vector3.new(headR * 2, headR * 2, headR * 2)
	head.Position   = Vector3.new(x, y + stemH + headR * 0.75, z)
	head.Anchored   = true
	head.CanCollide = false
	head.Color      = palette[1]
	head.Material   = Enum.Material.SmoothPlastic
	head.CastShadow = false
	head.Parent     = parent
end

-- ── PLACE PATCHES ────────────────────────────────────────────────────────────
-- Sparse grid: one candidate patch center per cell, filtered by noise.
-- Noise keeps flowers clustered in natural-looking zones rather than uniform.

local PATCH_GRID   = 85   -- studs between candidate patch centers
local PATCH_JITTER = 32   -- random offset applied to each candidate
local PATCH_SPREAD = 4.2  -- radius (studs) flowers scatter within a patch
local MIN_FLOWERS  = 4
local MAX_FLOWERS  = 11

local cols       = math.floor(MAP_SIZE / PATCH_GRID)
local patchCount = 0
local flowerCount = 0

for row = 0, cols - 1 do
	for col = 0, cols - 1 do
		local cx = math.clamp(-half + col * PATCH_GRID + PATCH_GRID / 2 + rng:NextNumber(-PATCH_JITTER, PATCH_JITTER), -half + 5, half - 5)
		local cz = math.clamp(-half + row * PATCH_GRID + PATCH_GRID / 2 + rng:NextNumber(-PATCH_JITTER, PATCH_JITTER), -half + 5, half - 5)

		-- Two-octave noise: large-scale zones + fine variation → ~18% of cells get flowers
		local n = math.noise(cx / 220, cz / 220) * 0.65 + math.noise(cx / 70, cz / 70) * 0.35
		if n < 0.08 then continue end

		local sy = getY(cx, cz)
		if not sy then continue end

		local palette = PALETTES[rng:NextInteger(1, #PALETTES)]
		local m = Instance.new("Model"); m.Name = "FlowerPatch"; m.Parent = fFolder

		local count = rng:NextInteger(MIN_FLOWERS, MAX_FLOWERS)
		for _ = 1, count do
			local a  = rng:NextNumber(0, math.pi * 2)
			local d  = rng:NextNumber(0, PATCH_SPREAD)
			local fx = cx + math.cos(a) * d
			local fz = cz + math.sin(a) * d
			local fy = getY(fx, fz)
			if fy then
				makeFlower(m, fx, fy, fz, palette)
				flowerCount += 1
			end
		end
		patchCount += 1
	end

	if row % 20 == 0 then
		print(string.format("Flowers %d/%d — %d patches, %d flowers", row, cols, patchCount, flowerCount))
	end
end

print(string.format("Flowers done! %d patches, %d flowers total. Save your place (Ctrl+S).", patchCount, flowerCount))
