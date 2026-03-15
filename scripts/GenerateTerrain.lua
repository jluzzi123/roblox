-- HILLY TERRAIN GENERATOR — Paste into Studio Command Bar
-- Replaces flat terrain with rolling hills using multi-octave Perlin noise
-- Takes 3-6 minutes. After it finishes, save (Ctrl+S) then re-run PlaceTrees.lua.

local Terrain = workspace.Terrain
local MAP_SIZE = 4800
local RESOLUTION = 8    -- stud resolution per cell (lower = smoother, slower)
local HALF = MAP_SIZE / 2
local BASE_Y = -64      -- solid bottom of terrain (below any hill valley)

local NOISE_SCALES = {
	{ scale = 700, amp = 22 },   -- large rolling hills
	{ scale = 280, amp = 11 },   -- medium undulation
	{ scale = 95,  amp = 4  },   -- surface roughness
}

local SEED_OFFSET = 7.3  -- shift noise so it looks different from tree density noise

local function getHeight(wx, wz)
	local h = 0
	for _, layer in ipairs(NOISE_SCALES) do
		h += math.noise(wx / layer.scale + SEED_OFFSET, wz / layer.scale + SEED_OFFSET) * layer.amp
	end
	return h
end

-- Clear existing terrain
print("[GenerateTerrain] Clearing terrain...")
Terrain:Clear()
task.wait(0.5)

local cells = MAP_SIZE / RESOLUTION
print(string.format("[GenerateTerrain] Generating %dx%d cells at %d-stud resolution...", cells, cells, RESOLUTION))

-- Pass 1: Fill solid ground columns from BASE_Y up to surface
print("[GenerateTerrain] Pass 1/2 — ground fill...")
for row = 0, cells - 1 do
	for col = 0, cells - 1 do
		local wx = -HALF + (col + 0.5) * RESOLUTION
		local wz = -HALF + (row + 0.5) * RESOLUTION
		local surfaceY = getHeight(wx, wz)

		local columnHeight = surfaceY - BASE_Y
		if columnHeight > 0 then
			local centerY = BASE_Y + columnHeight / 2
			Terrain:FillBlock(
				CFrame.new(wx, centerY, wz),
				Vector3.new(RESOLUTION, columnHeight, RESOLUTION),
				Enum.Material.Ground
			)
		end
	end

	if row % 50 == 0 then
		print(string.format("  Pass 1: %d/%d rows (%.0f%%)", row, cells, row / cells * 100))
		task.wait()
	end
end

-- Pass 2: Overwrite top 4 studs with Grass material
print("[GenerateTerrain] Pass 2/2 — grass surface...")
for row = 0, cells - 1 do
	for col = 0, cells - 1 do
		local wx = -HALF + (col + 0.5) * RESOLUTION
		local wz = -HALF + (row + 0.5) * RESOLUTION
		local surfaceY = getHeight(wx, wz)

		Terrain:FillBlock(
			CFrame.new(wx, surfaceY - 1, wz),
			Vector3.new(RESOLUTION, 4, RESOLUTION),
			Enum.Material.Grass
		)
	end

	if row % 50 == 0 then
		print(string.format("  Pass 2: %d/%d rows (%.0f%%)", row, cells, row / cells * 100))
		task.wait()
	end
end

print("[GenerateTerrain] Done! Hill heights range roughly ±37 studs from sea level.")
print("[GenerateTerrain] Save your place (Ctrl+S), then re-run PlaceTrees.lua to replace objects on the new terrain.")
