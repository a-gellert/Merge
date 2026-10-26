local M = {}

M.DISPLAY_WIDTH = 300
M.DISPLAY_HEIGHT = 600

-- Grid dimensions (4x4 for player at bottom, 4x4 for enemy at top)
M.GRID_COLS = 4
M.GRID_ROWS = 4
M.CELL_SIZE = 50
M.CELL_STEP = 56

-- X coordinates for columns 1..4 (world is centered around x = 200)
M.COL_X = { 116, 172, 228, 284 }

-- Y coordinates for Player rows 1..4 (bottom field, row 4 is front)
M.PLAYER_ROW_Y = { 112, 168, 224, 280 }

-- Y coordinates for Enemy rows 1..4 (top field, row 1 is front)
M.ENEMY_ROW_Y = { 364, 420, 476, 532 }

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

-- =============================================================================
-- TIERS
-- Every merge multiplies squad HP and DMG by TIER_GROWTH (2.2x each), so one
-- merged squad is ~1.2x stronger than the two squads it was made from
-- (Lanchester: strength ~ HP*DPS -> 4.84 vs 4.0). Merging ALWAYS feels good.
-- =============================================================================
M.TIER_GROWTH = 2.2
M.MAX_TIER = 60

-- Warriors per squad by tier. Each count has its own readable formation shape:
-- 3 triangle, 5 dice, 7 hex-flower, 9+ phalanx blocks: a crowd from the very first squad.
M.UNIT_COUNTS = { 3, 5, 7, 9, 12, 16, 20, 25, 30, 36, 42 }

-- Base squad stats at Tier 1 (squad totals, split between warriors)
M.UNIT_STATS = {
	[M.UNIT_MELEE] = {
		hp = 100,
		damage = 7.5,
		attack_interval = 0.65,
		attack_range = 30,
		speed = 80,
	},
	[M.UNIT_ARCHER] = {
		hp = 58,
		damage = 6.5,
		attack_interval = 0.9,
		attack_range = 175,
		speed = 62,
		miss_radius = 10,
	}
}

-- Economy
M.START_COINS = 30
M.PRICE_BASE = 10          -- coins per Tier-1 "value unit" in the shop
M.PRICE_LEVEL_STEP = 1.18  -- each purchase inside one level costs +18%
M.SHOP_GAP = 3             -- shop sells tier = best_tier - SHOP_GAP
M.SHOP_LUCKY_CHANCE = 0.12 -- chance that a bought squad arrives +1 tier

-- Trash Bin (Sell Zone)
M.TRASH_BIN_POS = vmath.vector3(200, 322, 0.6)
M.TRASH_BIN_RADIUS = 36

-- Projectiles
M.PROJECTILE_POOL_SIZE = 400
M.PROJECTILE_SPEED = 300
M.PROJECTILE_HIT_RADIUS = 20

-- Circle collision/separation constants
M.SQUAD_RADIUS = 18
M.REPEL_FORCE = 55

-- Arena bounds during battle
M.ARENA_MIN_X = 70
M.ARENA_MAX_X = 330
M.ARENA_MIN_Y = 90
M.ARENA_MAX_Y = 550

-- Visual palette
M.COLOR_OUTLINE = vmath.vector4(0.09, 0.10, 0.16, 1.0)
M.COLOR_PLAYER_MELEE = vmath.vector4(0.22, 0.62, 1.0, 1.0)  -- Azure
M.COLOR_PLAYER_ARCHER = vmath.vector4(0.20, 0.88, 0.62, 1.0) -- Mint
M.COLOR_PLAYER_ARROW = vmath.vector4(0.75, 0.95, 1.0, 1.0)
M.COLOR_ENEMY_MELEE = vmath.vector4(1.0, 0.30, 0.32, 1.0)   -- Candy red
M.COLOR_ENEMY_ARCHER = vmath.vector4(1.0, 0.62, 0.18, 1.0)  -- Sunset orange
M.COLOR_ENEMY_ARROW = vmath.vector4(1.0, 0.85, 0.65, 1.0)

-- Tier ring colors (cycles every 12 tiers, higher cycles get an aura)
M.TIER_RING_COLORS = {
	vmath.vector4(0.92, 0.94, 1.00, 0.95), -- T1 white
	vmath.vector4(0.40, 0.92, 0.36, 0.95), -- T2 lime
	vmath.vector4(0.20, 0.70, 1.00, 0.95), -- T3 azure
	vmath.vector4(0.70, 0.36, 1.00, 0.95), -- T4 purple
	vmath.vector4(1.00, 0.80, 0.10, 1.00), -- T5 gold
	vmath.vector4(1.00, 0.45, 0.12, 1.00), -- T6 flame
	vmath.vector4(1.00, 0.18, 0.40, 1.00), -- T7 ruby
	vmath.vector4(0.10, 0.95, 0.90, 1.00), -- T8 cyan
	vmath.vector4(1.00, 0.40, 0.85, 1.00), -- T9 pink
	vmath.vector4(0.65, 1.00, 0.20, 1.00), -- T10 acid
	vmath.vector4(1.00, 1.00, 1.00, 1.00), -- T11 diamond
	vmath.vector4(1.00, 0.70, 0.20, 1.00), -- T12 legend
}

M.COLOR_CELL_PLAYER = vmath.vector4(0.10, 0.30, 0.22, 0.30)
M.COLOR_CELL_ENEMY = vmath.vector4(0.30, 0.16, 0.12, 0.28)
M.COLOR_CELL_MERGE = vmath.vector4(1.0, 0.85, 0.20, 0.95)

-- Arena tint per chapter (cheap novelty every 10 levels)
M.CHAPTER_TINTS = {
	vmath.vector4(1.00, 1.00, 1.00, 1), -- meadow
	vmath.vector4(1.05, 0.95, 0.78, 1), -- desert
	vmath.vector4(0.82, 0.92, 1.08, 1), -- frost
	vmath.vector4(0.80, 0.72, 0.95, 1), -- dusk
	vmath.vector4(1.08, 0.78, 0.68, 1), -- volcano
	vmath.vector4(0.72, 0.95, 0.85, 1), -- jungle
}

function M.get_tier_color(tier)
	local n = #M.TIER_RING_COLORS
	return M.TIER_RING_COLORS[((tier - 1) % n) + 1]
end

function M.get_chapter_tint(chapter)
	local n = #M.CHAPTER_TINTS
	return M.CHAPTER_TINTS[((chapter - 1) % n) + 1]
end

function M.get_unit_count(tier)
	local idx = math.max(1, math.min(tier, #M.UNIT_COUNTS))
	return M.UNIT_COUNTS[idx]
end

-- Value of a squad in Tier-1 units (two of tier t merge into one of t+1)
function M.get_tier_value(tier)
	return 2 ^ (tier - 1)
end

function M.get_tier_mult(tier)
	return M.TIER_GROWTH ^ (tier - 1)
end

function M.get_squad_stats(unit_type, tier)
	local base = M.UNIT_STATS[unit_type] or M.UNIT_STATS[M.UNIT_MELEE]
	local count = M.get_unit_count(tier)
	local mult = M.get_tier_mult(tier)
	return {
		max_hp = base.hp * mult,
		damage = base.damage * mult,
		attack_interval = base.attack_interval,
		attack_range = base.attack_range,
		speed = base.speed,
		miss_radius = base.miss_radius or 0,
		unit_count = count,
	}
end

-- Power rating shown in UI ("number goes up"): geometric mean of HP and DPS
function M.get_squad_power(unit_type, tier)
	local base = M.UNIT_STATS[unit_type] or M.UNIT_STATS[M.UNIT_MELEE]
	local dps = base.damage / base.attack_interval
	return math.sqrt(base.hp * dps) * M.get_tier_mult(tier) * 0.35
end

-- Visual scale of one warrior sprite for a squad of `count`
function M.get_warrior_scale(count)
	if count <= 1 then return 0.62 end
	if count <= 3 then return 0.5 end
	if count <= 7 then return 0.44 end
	if count <= 12 then return 0.38 end
	if count <= 20 then return 0.34 end
	return 0.3
end

local function add_ring(offsets, ring_count, radius, angle_offset)
	angle_offset = angle_offset or 0
	local step = (math.pi * 2) / ring_count
	for i = 1, ring_count do
		local angle = (i - 1) * step + angle_offset
		table.insert(offsets, vmath.vector3(math.cos(angle) * radius, math.sin(angle) * radius, 0.05))
	end
end

local PHALANX = {
	[9] = { 3, 3 }, [12] = { 4, 3 }, [16] = { 4, 4 }, [20] = { 5, 4 },
	[25] = { 5, 5 }, [30] = { 6, 5 }, [36] = { 6, 6 }, [42] = { 7, 6 },
}

-- Formation offsets; forward is +Y (enemy squads mirror Y).
-- Front-most warriors come first so losses eat the back ranks last.
function M.get_formation_offsets(count)
	local offsets = {}
	if count == 1 then
		table.insert(offsets, vmath.vector3(0, 0, 0.05))
	elseif count == 3 then
		table.insert(offsets, vmath.vector3(0, 7, 0.05))
		table.insert(offsets, vmath.vector3(-8, -5, 0.05))
		table.insert(offsets, vmath.vector3(8, -5, 0.05))
	elseif count == 5 then
		table.insert(offsets, vmath.vector3(0, 0, 0.06))
		add_ring(offsets, 4, 11, math.pi * 0.25)
	elseif count == 7 then
		table.insert(offsets, vmath.vector3(0, 0, 0.06))
		add_ring(offsets, 6, 11.5, math.pi / 6)
	elseif PHALANX[count] then
		local cols, rows = PHALANX[count][1], PHALANX[count][2]
		local span = 42
		local sx = math.min(10, span / math.max(1, cols - 1))
		local sy = math.min(9, span / math.max(1, rows - 1))
		for r = rows, 1, -1 do
			for c = 1, cols do
				-- brick offset on every other rank for a lively crowd look
				local shift = (r % 2 == 0) and sx * 0.25 or -sx * 0.25
				local x = (c - (cols + 1) * 0.5) * sx + shift
				local y = (r - (rows + 1) * 0.5) * sy
				table.insert(offsets, vmath.vector3(x, y, 0.05 + (rows - r) * 0.001))
			end
		end
	else
		local GOLDEN_ANGLE = 2.39996323
		for i = 1, count do
			local r = 4.0 * math.sqrt(i - 1)
			local theta = (i - 1) * GOLDEN_ANGLE
			table.insert(offsets, vmath.vector3(math.cos(theta) * r, math.sin(theta) * r, 0.05))
		end
	end
	return offsets
end

return M
