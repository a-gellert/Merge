local M = {}

M.DISPLAY_WIDTH = 300
M.DISPLAY_HEIGHT = 600

-- Grid dimensions (4x4 for player at bottom, 4x4 for enemy at top)
M.GRID_COLS = 4
M.GRID_ROWS = 4
M.CELL_SIZE = 54
M.CELL_STEP = 60

-- X coordinates for columns 1..4 (centered around x = 200)
M.COL_X = { 110, 170, 230, 290 }

-- Y coordinates for Player rows 1..4 (bottom field, row 4 is front)
M.PLAYER_ROW_Y = { 130, 190, 250, 310 }

-- Y coordinates for Enemy rows 1..4 (top field, row 1 is front)
M.ENEMY_ROW_Y = { 365, 425, 485, 545 }

-- Fibonacci sequence for number of visual warriors in a squad per tier
M.FIBONACCI = { 1, 3, 5, 9, 13, 21, 34, 55, 89, 144 }--специально исправил!
M.MAX_TIER = #M.FIBONACCI

-- Teams
M.TEAM_PLAYER = "player"
M.TEAM_ENEMY = "enemy"

-- Unit types
M.UNIT_MELEE = "melee"
M.UNIT_ARCHER = "archer"

-- Battle phases
M.PHASE_PREP = "PREPARATION"
M.PHASE_BATTLE = "BATTLE"
M.PHASE_VICTORY = "VICTORY"
M.PHASE_DEFEAT = "DEFEAT"

-- Base unit stats
M.UNIT_STATS = {
	[M.UNIT_MELEE] = {
		hp = 110,
		damage = 24,
		attack_interval = 0.7,
		attack_range = 28,
		speed = 85,
	},
	[M.UNIT_ARCHER] = {
		hp = 70,
		damage = 16,
		attack_interval = 1.05,
		attack_range = 195,
		speed = 70,
		miss_radius = 14, -- Archers can miss slightly
	}
}

-- Economy settings
M.START_COINS = 10
M.BASE_BUY_COST = 10
M.BUY_COST_STEP = 5
M.KILL_REWARD = 6
M.WIN_REWARD = 15

-- Projectile Pool
M.PROJECTILE_POOL_SIZE = 150
M.PROJECTILE_SPEED = 420
M.PROJECTILE_HIT_RADIUS = 20

-- Circle collision/separation constants
M.SQUAD_RADIUS = 16
M.REPEL_FORCE = 45

-- Visual Tints (Juicy candy palette & cartoon styling)
M.COLOR_BG = vmath.vector4(0.055, 0.075, 0.122, 1.0) -- #0E131F Noble Deep Navy
M.COLOR_OUTLINE = vmath.vector4(0.06, 0.08, 0.12, 1.0) -- Deep 2-3px dark cartoon outline

M.COLOR_PLAYER_MELEE = vmath.vector4(0.20, 0.68, 1.0, 1.0)  -- Vibrant Azure Blue
M.COLOR_PLAYER_ARCHER = vmath.vector4(0.15, 0.90, 0.55, 1.0) -- Vibrant Mint Emerald
M.COLOR_PLAYER_ARROW = vmath.vector4(0.15, 0.10, 0.9, 1.0) 
M.COLOR_ENEMY_MELEE = vmath.vector4(1.0, 0.25, 0.30, 1.0)   -- Candy Red
M.COLOR_ENEMY_ARCHER = vmath.vector4(1.0, 0.55, 0.15, 1.0)  -- Vibrant Sunset Orange
M.COLOR_ENEMY_ARROW = vmath.vector4(0.85, 0.10, 0.05, 1.0) 

-- Juicy Candy Tier Ring Colors:
M.TIER_RING_COLORS = {
	vmath.vector4(0.95, 0.96, 1.0, 0.90),  -- T1: Silver-White with bright shine
	vmath.vector4(0.31, 0.93, 0.32, 0.90), -- T2: Juicy Lime (#4EED52)
	vmath.vector4(0.16, 0.66, 1.0, 0.90),  -- T3: Rich Azure (#29A8FF)
	vmath.vector4(0.74, 0.23, 1.0, 0.90),  -- T4: Neon Purple (#BD3BFF)
	vmath.vector4(1.0, 0.78, 0.05, 0.95),  -- T5: Amber Gold
	vmath.vector4(1.0, 0.38, 0.12, 0.95),  -- T6: Flame Orange
	vmath.vector4(1.0, 0.12, 0.35, 1.0),   -- T7+: Neon Ruby
}

-- Arena Floor Mat Colors (Enemy Red vs Player Blue zones)
M.COLOR_FLOOR_ENEMY = vmath.vector4(0.15, 0.06, 0.09, 0.90)  -- Subtle Wine-Red floor zone
M.COLOR_FLOOR_PLAYER = vmath.vector4(0.06, 0.11, 0.20, 0.90) -- Subtle Midnight-Blue floor zone

-- Rounded Cell Tiles ("Доска с лунками" - 10-15% lighter than floor)
M.COLOR_CELL_PLAYER_BG = vmath.vector4(0.11, 0.17, 0.27, 0.95)
M.COLOR_CELL_PLAYER_BORDER = vmath.vector4(0.20, 0.32, 0.48, 0.75)
M.COLOR_CELL_ENEMY_BG = vmath.vector4(0.22, 0.10, 0.14, 0.95)
M.COLOR_CELL_ENEMY_BORDER = vmath.vector4(0.42, 0.18, 0.24, 0.75)

M.COLOR_CELL_HIGHLIGHT = vmath.vector4(0.35, 0.92, 0.50, 0.95)
M.COLOR_CELL_MERGE = vmath.vector4(1.0, 0.85, 0.20, 0.95)

function M.get_unit_count(tier)
	local idx = math.max(1, math.min(tier, #M.FIBONACCI))
	return M.FIBONACCI[idx]
end

function M.get_squad_stats(unit_type, tier)
	local base = M.UNIT_STATS[unit_type] or M.UNIT_STATS[M.UNIT_MELEE]
	local count = M.get_unit_count(tier)
	local tier_bonus = 1 + (tier - 1) * 0.15
	local mult = count * tier_bonus
	return {
		max_hp = math.floor(base.hp * mult),
		damage = math.floor(base.damage * mult),
		attack_interval = base.attack_interval,
		attack_range = base.attack_range,
		speed = base.speed,
		miss_radius = base.miss_radius or 0,
		unit_count = count
	}
end

local function add_ring(offsets, ring_count, radius, angle_offset)
	angle_offset = angle_offset or 0
	local step = (math.pi * 2) / ring_count
	for i = 1, ring_count do
		local angle = (i - 1) * step + angle_offset
		table.insert(offsets, vmath.vector3(math.cos(angle) * radius, math.sin(angle) * radius, 0.05))
	end
end

function M.get_formation_offsets(count)
	local offsets = {}

	if count == 1 then
		table.insert(offsets, vmath.vector3(0, 0, 0.05))
	elseif count == 2 then
		table.insert(offsets, vmath.vector3(-6.5, 0, 0.05))
		table.insert(offsets, vmath.vector3(6.5, 0, 0.05))
	elseif count == 3 then
		table.insert(offsets, vmath.vector3(0, 6, 0.05))
		table.insert(offsets, vmath.vector3(-6, -4, 0.05))
		table.insert(offsets, vmath.vector3(6, -4, 0.05))
	elseif count == 5 then
		table.insert(offsets, vmath.vector3(0, 0, 0.05))
		add_ring(offsets, 4, 7.5, math.pi * 0.25)
	elseif count == 8 then
		table.insert(offsets, vmath.vector3(0, 0, 0.05))
		add_ring(offsets, 7, 9.5)
	elseif count == 13 then
		table.insert(offsets, vmath.vector3(0, 0, 0.05))
		add_ring(offsets, 4, 6.0)
		add_ring(offsets, 8, 11.5, math.pi / 8)
	else
		local GOLDEN_ANGLE = 2.39996323
		local SPREAD_FACTOR = 4.0
		for i = 1, count do
			local r = SPREAD_FACTOR * math.sqrt(i - 1)
			local theta = (i - 1) * GOLDEN_ANGLE
			table.insert(offsets, vmath.vector3(math.cos(theta) * r, math.sin(theta) * r, 0.05))
		end
	end
	return offsets
end

return M
