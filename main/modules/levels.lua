-- Procedural campaign with a two-level "Sawtooth" difficulty curve.
-- Full design notes and the tuning table: docs/KNOWLEDGE_BASE.md
local config = require("main.modules.config")

local M = {}

local MELEE = config.UNIT_MELEE
local ARCHER = config.UNIT_ARCHER

M.CHAPTER_SIZE = 10
M.CAMPAIGN_LEVELS = 300 -- ~4 hours of content at human pace, endless after that

-- Expected top tier of a player who merges reasonably (smooth baseline).
-- Fast early climb (T1 -> T5 in ~10 levels), then a steady ~1 tier / 10 levels.
M.CURVE_A = 2.6
M.CURVE_B = 4.0
M.CURVE_C = 0.115

-- Sawtooth multipliers on enemy power, by step inside a 10-level chapter:
-- relief -> climb -> mini-boss (5) -> breather -> climb -> chapter boss (10).
-- The teeth get sharper with every chapter (amplitude 50% in ch.1 -> 100% from ch.3).
M.SAWTOOTH = { 0.78, 0.86, 0.93, 1.00, 1.14, 0.90, 1.00, 1.07, 1.14, 1.32 }

-- Enemy power in "army units" (how many top-tier squads the player should field).
-- Early armies are small, so the factor ramps in over the first 50 levels.
M.ARMY_FACTOR = 3.6
M.ARMY_RAMP_LEVELS = 50
M.ARMY_RAMP_START = 0.42
M.ARMY_RAMP_POW = 1.6

-- Coins a level pays out, in "shop purchases" at the expected shop tier
M.INCOME_EARLY = 5.0
M.INCOME_LATE = 2.6

function M.target_tier(level)
	return 1 + M.CURVE_A * math.log(1 + level / M.CURVE_B) + M.CURVE_C * level
end

function M.get_chapter(level)
	return math.floor((level - 1) / M.CHAPTER_SIZE) + 1
end

function M.get_step(level)
	return (level - 1) % M.CHAPTER_SIZE + 1
end

function M.is_boss(level)
	return M.get_step(level) == M.CHAPTER_SIZE
end

function M.is_mini_boss(level)
	return M.get_step(level) == 5
end

function M.get_difficulty(level)
	local amp = math.min(1, 0.5 + 0.25 * (M.get_chapter(level) - 1))
	return 1 + (M.SAWTOOTH[M.get_step(level)] - 1) * amp
end

-- Price of one shop squad at the shop tier we expect on this level
function M.expected_unit_price(level)
	local shop_tier = math.max(1, math.floor(M.target_tier(level)) - config.SHOP_GAP)
	return config.PRICE_BASE * config.get_tier_value(shop_tier)
end

function M.get_income(level)
	local k = math.min(1, (level - 1) / 25)
	local units = M.INCOME_EARLY + (M.INCOME_LATE - M.INCOME_EARLY) * k
	local mult = M.get_difficulty(level) -- bosses pay more
	return math.floor(M.expected_unit_price(level) * units * mult + 0.5)
end

-- Formation templates: role list in priority order. B = boss/captain melee,
-- M = melee, A = archer. Picked by number of squads.
local SLOTS_FRONT = { { 1, 2 }, { 1, 3 }, { 1, 1 }, { 1, 4 }, { 2, 2 }, { 2, 3 }, { 2, 1 }, { 2, 4 } }
local SLOTS_BACK = { { 4, 2 }, { 4, 3 }, { 3, 2 }, { 3, 3 }, { 4, 1 }, { 4, 4 }, { 3, 1 }, { 3, 4 } }

-- Small deterministic RNG so a level always looks the same
local function rng(seed)
	local s = seed % 2147483647
	if s <= 0 then s = s + 2147483646 end
	return function()
		s = (s * 16807) % 2147483647
		return (s - 1) / 2147483646
	end
end

local function tier_for_power(unit_type, power)
	local p1 = config.get_squad_power(unit_type, 1)
	local t = 1 + math.log(math.max(power, 1e-9) / p1) / math.log(config.TIER_GROWTH)
	return math.max(1, math.min(config.MAX_TIER, math.floor(t + 0.5)))
end

-- Total enemy power budget for a level (before pity reduction)
function M.get_enemy_budget(level)
	local t = M.target_tier(level)
	local top_power = config.get_squad_power(MELEE, 1) * config.TIER_GROWTH ^ (t - 1)
	local ramp = M.ARMY_RAMP_START + (1 - M.ARMY_RAMP_START) * math.min(1, (level - 1) / M.ARMY_RAMP_LEVELS) ^ M.ARMY_RAMP_POW
	return top_power * M.ARMY_FACTOR * ramp * M.get_difficulty(level)
end

local HANDMADE = {
	-- Tutorial: 2 tiny melee vs player's merged T2 + archer
	[1] = {
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 1 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 1 },
		},
		initial_player = {
			{ row = 4, col = 2, unit_type = MELEE, tier = 1 },
			{ row = 1, col = 2, unit_type = ARCHER, tier = 1 },
		},
	},
	[2] = {
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 2 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 1 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 1 },
		},
	},
}

local function build_enemies(level)
	local r = rng(level * 7919 + 13)
	local budget = M.get_enemy_budget(level)
	local boss = M.is_boss(level) or M.is_mini_boss(level)

	-- Crowd grows with progress: 3 squads early, up to 10 late
	local count = math.min(10, 3 + math.floor(level / 5))
	if M.get_step(level) == 1 then count = math.max(3, count - 1) end

	-- Archer share wobbles per level for variety (25%..45%)
	local archer_share = 0.25 + r() * 0.2
	local n_archers = math.max(1, math.floor(count * archer_share + 0.5))
	if level <= 3 then n_archers = 1 end
	local n_melee = count - n_archers

	local slots = {}
	for i = 1, n_melee do
		local w = (i <= 2) and 1.3 or 1.0
		table.insert(slots, { unit_type = MELEE, weight = w, cell = SLOTS_FRONT[i] })
	end
	for i = 1, n_archers do
		table.insert(slots, { unit_type = ARCHER, weight = 0.9, cell = SLOTS_BACK[i] })
	end
	if boss then
		slots[1].weight = M.is_boss(level) and 4.0 or 2.6
		slots[1].is_boss = true
	end

	local total_w = 0
	for _, s in ipairs(slots) do total_w = total_w + s.weight end

	-- Spread the budget; carry rounding error into the next slot
	local enemies = {}
	local carry = 0
	for _, s in ipairs(slots) do
		-- carry never starves a slot below 45% of its share (no stray T1 among T16s)
		local share = budget * s.weight / total_w
		local want = math.max(share * 0.45, share + carry)
		local tier = tier_for_power(s.unit_type, want)
		local got = config.get_squad_power(s.unit_type, tier)
		carry = want - got
		table.insert(enemies, {
			row = s.cell[1], col = s.cell[2],
			unit_type = s.unit_type, tier = tier, is_boss = s.is_boss,
		})
	end
	return enemies
end

function M.get_level(level_num)
	local data = HANDMADE[level_num]
	local enemies = data and data.enemies or build_enemies(level_num)
	return {
		enemies = enemies,
		initial_player = data and data.initial_player,
		income = M.get_income(level_num),
		is_boss = M.is_boss(level_num),
		is_mini_boss = M.is_mini_boss(level_num),
		chapter = M.get_chapter(level_num),
		step = M.get_step(level_num),
	}
end

return M
