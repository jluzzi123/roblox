-- FOREST OBJECTS v2 — diverse trees, bushes, rocks
-- Paste into Studio Command Bar. Takes 3-6 minutes.

local SEED     = 42
local MAP_SIZE = 4800
local rng      = Random.new(SEED)
local half     = MAP_SIZE / 2

-- Clear old objects
for _, name in ipairs({"Trees", "Bushes", "Rocks"}) do
	local f = workspace:FindFirstChild(name)
	if f then f:Destroy() end
end
local tFolder = Instance.new("Folder"); tFolder.Name = "Trees";  tFolder.Parent = workspace
local bFolder = Instance.new("Folder"); bFolder.Name = "Bushes"; bFolder.Parent = workspace
local rFolder = Instance.new("Folder"); rFolder.Name = "Rocks";  rFolder.Parent = workspace

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = {workspace.Terrain}

local function getY(x, z)
	local hit = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), params)
	return hit and hit.Position.Y or nil
end

local function ball(parent, pos, size, color, mat)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = size
	p.Position = pos
	p.Anchored = true
	p.CanCollide = false
	p.Color = color
	p.Material = mat
	p.CastShadow = false
	p.Parent = parent
end

local function cylinder(parent, cf, len, r, color, mat)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(len, r*2, r*2)
	p.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	p.Anchored = true
	p.CanCollide = true
	p.Color = color
	p.Material = mat
	p.CastShadow = false
	p.Parent = parent
end

-- ── TREE TYPES ──────────────────────────────────────────────────────────────

-- Oak: wide rounded crown, medium height
local function makeOak(wx, wz, sy)
	local m = Instance.new("Model"); m.Name = "Oak"; m.Parent = tFolder
	local th = rng:NextNumber(13, 26)
	local tr = rng:NextNumber(0.5, 1.1)
	local cr = rng:NextNumber(7, 13)
	local tc = Color3.fromRGB(rng:NextInteger(38,55), rng:NextInteger(24,38), rng:NextInteger(10,20))
	local cc = Color3.fromRGB(rng:NextInteger(18,42), rng:NextInteger(58,98), rng:NextInteger(14,32))
	cylinder(m, CFrame.new(wx, sy+th/2, wz), th, tr, tc, Enum.Material.Wood)
	ball(m, Vector3.new(wx, sy+th+cr*0.55, wz), Vector3.new(cr*2, cr*1.4, cr*2), cc, Enum.Material.Grass)
	local r2 = cr * rng:NextNumber(0.48, 0.72)
	local a  = rng:NextNumber(0, math.pi*2)
	ball(m, Vector3.new(wx+math.cos(a)*cr*0.5, sy+th+cr*0.2+r2, wz+math.sin(a)*cr*0.5), Vector3.new(r2*2, r2*1.5, r2*2), cc, Enum.Material.Grass)
	local r3 = cr * rng:NextNumber(0.28, 0.42)
	ball(m, Vector3.new(wx, sy+th+cr*1.1+r3, wz), Vector3.new(r3*2, r3*2, r3*2), cc, Enum.Material.Grass)
end

-- Pine: tall, narrow, stacked layers
local function makePine(wx, wz, sy)
	local m = Instance.new("Model"); m.Name = "Pine"; m.Parent = tFolder
	local th = rng:NextNumber(20, 42)
	local tr = rng:NextNumber(0.3, 0.7)
	local tc = Color3.fromRGB(rng:NextInteger(30,48), rng:NextInteger(18,30), rng:NextInteger(8,15))
	local cc = Color3.fromRGB(rng:NextInteger(10,22), rng:NextInteger(38,68), rng:NextInteger(10,20))
	cylinder(m, CFrame.new(wx, sy+th/2, wz), th, tr, tc, Enum.Material.Wood)
	local layers = rng:NextInteger(3, 5)
	for i = 1, layers do
		local t  = (i-1) / (layers-1)
		local ly = sy + th * (0.3 + t * 0.6)
		local lr = rng:NextNumber(2, 5.5) * (1.3 - t * 0.9)
		ball(m, Vector3.new(wx, ly, wz), Vector3.new(lr*2, lr*1.6, lr*2), cc, Enum.Material.Grass)
	end
end

-- Dead tree: bare trunk + branch stubs
local function makeDeadTree(wx, wz, sy)
	local m = Instance.new("Model"); m.Name = "DeadTree"; m.Parent = tFolder
	local th = rng:NextNumber(10, 20)
	local tr = rng:NextNumber(0.4, 0.85)
	local tc = Color3.fromRGB(rng:NextInteger(58,82), rng:NextInteger(52,72), rng:NextInteger(46,64))
	cylinder(m, CFrame.new(wx, sy+th/2, wz), th, tr, tc, Enum.Material.Wood)
	local branches = rng:NextInteger(2, 4)
	for _ = 1, branches do
		local bLen    = rng:NextNumber(2.5, 6)
		local bR      = tr * rng:NextNumber(0.28, 0.5)
		local bY      = sy + th * rng:NextNumber(0.55, 0.92)
		local bYaw    = rng:NextNumber(0, math.pi*2)
		local bTilt   = rng:NextNumber(math.rad(35), math.rad(65))
		-- Place branch: rotate around trunk then tilt outward
		local baseCF  = CFrame.new(wx, bY, wz) * CFrame.Angles(0, bYaw, 0)
		local branchCF = baseCF * CFrame.new(bLen/2, 0, 0) * CFrame.Angles(0, 0, bTilt)
		cylinder(m, branchCF, bLen, bR, tc, Enum.Material.Wood)
	end
end

-- Shrub tree: short and bushy
local function makeShrub(wx, wz, sy)
	local m = Instance.new("Model"); m.Name = "ShrubTree"; m.Parent = tFolder
	local th = rng:NextNumber(4, 11)
	local tr = rng:NextNumber(0.3, 0.65)
	local cr = rng:NextNumber(3, 7)
	local tc = Color3.fromRGB(rng:NextInteger(38,55), rng:NextInteger(24,38), rng:NextInteger(10,20))
	local cc = Color3.fromRGB(rng:NextInteger(14,36), rng:NextInteger(52,90), rng:NextInteger(10,28))
	cylinder(m, CFrame.new(wx, sy+th/2, wz), th, tr, tc, Enum.Material.Wood)
	for i = 1, 3 do
		local a = (i-1) * math.pi*2/3 + rng:NextNumber(-0.4, 0.4)
		local r = cr * rng:NextNumber(0.62, 1.0)
		ball(m, Vector3.new(wx+math.cos(a)*cr*0.42, sy+th+r*0.55, wz+math.sin(a)*cr*0.42), Vector3.new(r*2, r*1.2, r*2), cc, Enum.Material.Grass)
	end
end

-- ── PLACE TREES ─────────────────────────────────────────────────────────────

local TREE_GRID   = 42
local TREE_JITTER = 16
local tcols       = math.floor(MAP_SIZE / TREE_GRID)
local treePlaced  = 0

for row = 0, tcols-1 do
	for col = 0, tcols-1 do
		local wx = math.clamp(-half + col*TREE_GRID + TREE_GRID/2 + rng:NextNumber(-TREE_JITTER, TREE_JITTER), -half+10, half-10)
		local wz = math.clamp(-half + row*TREE_GRID + TREE_GRID/2 + rng:NextNumber(-TREE_JITTER, TREE_JITTER), -half+10, half-10)

		local d = math.noise(wx/300, wz/300)*0.6 + math.noise(wx/90, wz/90)*0.4
		if d < -0.05 then continue end

		local sy = getY(wx, wz)
		if not sy then continue end

		-- Zone noise picks tree type — creates biome-like patches
		local tn = math.noise(wx/400 + 10, wz/400 + 10)
		if     tn >  0.15 then makePine(wx, wz, sy)
		elseif tn > -0.05 then makeOak(wx, wz, sy)
		elseif tn > -0.2  then makeShrub(wx, wz, sy)
		else                    makeDeadTree(wx, wz, sy)
		end
		treePlaced += 1
	end
	if row % 20 == 0 then print(string.format("Trees %d/%d — %d placed", row, tcols, treePlaced)) end
end
print("Trees done: " .. treePlaced)

-- ── PLACE BUSHES ────────────────────────────────────────────────────────────

local BUSH_GRID   = 32
local BUSH_JITTER = 12
local bcols       = math.floor(MAP_SIZE / BUSH_GRID)
local bushPlaced  = 0

for row = 0, bcols-1 do
	for col = 0, bcols-1 do
		local wx = math.clamp(-half + col*BUSH_GRID + BUSH_GRID/2 + rng:NextNumber(-BUSH_JITTER, BUSH_JITTER), -half+5, half-5)
		local wz = math.clamp(-half + row*BUSH_GRID + BUSH_GRID/2 + rng:NextNumber(-BUSH_JITTER, BUSH_JITTER), -half+5, half-5)

		local d = math.noise(wx/180, wz/180)*0.5 + math.noise(wx/55, wz/55)*0.5
		if d < 0.08 then continue end

		local sy = getY(wx, wz)
		if not sy then continue end

		local m  = Instance.new("Model"); m.Name = "Bush"; m.Parent = bFolder
		local br = rng:NextNumber(1.2, 3.2)
		local bc = Color3.fromRGB(rng:NextInteger(10,28), rng:NextInteger(42,78), rng:NextInteger(8,24))
		for _ = 1, rng:NextInteger(2, 4) do
			local a    = rng:NextNumber(0, math.pi*2)
			local dist = rng:NextNumber(0, br*0.55)
			local r    = br * rng:NextNumber(0.58, 1.0)
			ball(m, Vector3.new(wx+math.cos(a)*dist, sy+r*0.48, wz+math.sin(a)*dist), Vector3.new(r*2, r*1.15, r*2), bc, Enum.Material.Grass)
		end
		bushPlaced += 1
	end
	if row % 30 == 0 then print(string.format("Bushes %d/%d — %d placed", row, bcols, bushPlaced)) end
end
print("Bushes done: " .. bushPlaced)

-- ── PLACE ROCKS ─────────────────────────────────────────────────────────────

local ROCK_GRID   = 110
local ROCK_JITTER = 40
local rcols       = math.floor(MAP_SIZE / ROCK_GRID)
local rockPlaced  = 0

local rockColors = {
	Color3.fromRGB(85, 88, 90), Color3.fromRGB(72, 75, 78),
	Color3.fromRGB(95, 92, 88), Color3.fromRGB(65, 68, 72),
	Color3.fromRGB(100, 96, 92),
}

for row = 0, rcols-1 do
	for col = 0, rcols-1 do
		local wx = math.clamp(-half + col*ROCK_GRID + ROCK_GRID/2 + rng:NextNumber(-ROCK_JITTER, ROCK_JITTER), -half+5, half-5)
		local wz = math.clamp(-half + row*ROCK_GRID + ROCK_GRID/2 + rng:NextNumber(-ROCK_JITTER, ROCK_JITTER), -half+5, half-5)

		if math.noise(wx/160 + 50, wz/160 + 50) < 0.08 then continue end

		local sy = getY(wx, wz)
		if not sy then continue end

		local m  = Instance.new("Model"); m.Name = "Rocks"; m.Parent = rFolder
		local rc = rockColors[rng:NextInteger(1, #rockColors)]

		if rng:NextNumber() > 0.45 then
			-- Boulder cluster
			for _ = 1, rng:NextInteger(2, 5) do
				local a    = rng:NextNumber(0, math.pi*2)
				local dist = rng:NextNumber(0, 4.5)
				local rs   = rng:NextNumber(1.0, 4.0)
				local rc2  = rockColors[rng:NextInteger(1, #rockColors)]
				local p = Instance.new("Part")
				p.Shape    = Enum.PartType.Ball
				p.Size     = Vector3.new(rs*rng:NextNumber(0.8,1.4), rs*rng:NextNumber(0.55,0.9), rs*rng:NextNumber(0.8,1.3))
				p.CFrame   = CFrame.new(wx+math.cos(a)*dist, sy+rs*0.32, wz+math.sin(a)*dist) * CFrame.Angles(rng:NextNumber(-0.3,0.3), rng:NextNumber(0,math.pi*2), rng:NextNumber(-0.3,0.3))
				p.Anchored = true
				p.Color    = rc2
				p.Material = Enum.Material.Slate
				p.CastShadow = false
				p.Parent   = m
			end
		else
			-- Single large boulder
			local rs = rng:NextNumber(3, 8)
			local p = Instance.new("Part")
			p.Shape    = Enum.PartType.Ball
			p.Size     = Vector3.new(rs*rng:NextNumber(0.9,1.5), rs*rng:NextNumber(0.6,0.9), rs*rng:NextNumber(0.9,1.4))
			p.CFrame   = CFrame.new(wx, sy+rs*0.28, wz) * CFrame.Angles(rng:NextNumber(-0.2,0.2), rng:NextNumber(0,math.pi*2), rng:NextNumber(-0.2,0.2))
			p.Anchored = true
			p.Color    = rc
			p.Material = Enum.Material.Slate
			p.CastShadow = false
			p.Parent   = m
		end
		rockPlaced += 1
	end
end
print("Rocks done: " .. rockPlaced)
print("ALL DONE! Save your place (Ctrl+S).")
