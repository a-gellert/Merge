-- Meta-Progression Talents Module: persistent player upgrades, formulas, save/load
local M = {}

local TALENT_DEFS = {
	{
		id = "melee",
		icon = "talent_melee",
		name_key = "TALENT_MELEE_NAME",
		desc_key = "TALENT_MELEE_DESC",
		base_cost = 40,
		cost_mult = 1.55,
		max_level = 25,
		bonus_per_level = 0.05, -- +5% Melee HP & DPS
		unit_type = 1,
	},
	{
		id = "archer",
		icon = "talent_archer",
		name_key = "TALENT_ARCHER_NAME",
		desc_key = "TALENT_ARCHER_DESC",
		base_cost = 40,
		cost_mult = 1.55,
		max_level = 25,
		bonus_per_level = 0.05, -- +5% Archer DPS
		unit_type = 2,
	},
	{
		id = "gold",
		icon = "talent_gold",
		name_key = "TALENT_GOLD_NAME",
		desc_key = "TALENT_GOLD_DESC",
		base_cost = 50,
		cost_mult = 1.60,
		max_level = 25,
		bonus_per_level = 0.08, -- +8% Gold from battles and kills
	},
	{
		id = "start",
		icon = "talent_start",
		name_key = "TALENT_START_NAME",
		desc_key = "TALENT_START_DESC",
		base_cost = 60,
		cost_mult = 1.65,
		max_level = 20,
		bonus_per_level = 10, -- +10 Starting Coins
	},
}

local levels = {
	melee = 0,
	archer = 0,
	gold = 0,
	start = 0,
}

function M.get_defs()
	return TALENT_DEFS
end

function M.get_level(id)
	return levels[id] or 0
end

function M.get_cost(id)
	local def
	for i = 1, #TALENT_DEFS do
		if TALENT_DEFS[i].id == id then
			def = TALENT_DEFS[i]
			break
		end
	end
	if not def then return 999999 end
	local current = levels[id] or 0
	if current >= def.max_level then return nil end
	return math.floor(def.base_cost * math.pow(def.cost_mult, current))
end

function M.is_max(id)
	local def
	for i = 1, #TALENT_DEFS do
		if TALENT_DEFS[i].id == id then
			def = TALENT_DEFS[i]
			break
		end
	end
	if not def then return true end
	return (levels[id] or 0) >= def.max_level
end

function M.can_afford(id, available_coins)
	local cost = M.get_cost(id)
	if not cost then return false end
	return available_coins >= cost
end

function M.has_affordable(available_coins)
	if not available_coins or available_coins <= 0 then return false end
	for i = 1, #TALENT_DEFS do
		if M.can_afford(TALENT_DEFS[i].id, available_coins) then
			return true
		end
	end
	return false
end

function M.upgrade(id, available_coins)
	local cost = M.get_cost(id)
	if not cost or available_coins < cost then return false, available_coins end
	levels[id] = (levels[id] or 0) + 1
	return true, available_coins - cost
end

-- Multipliers for stats and economy
function M.get_melee_multiplier()
	return 1.0 + (levels.melee or 0) * 0.05
end

function M.get_archer_multiplier()
	return 1.0 + (levels.archer or 0) * 0.05
end

function M.get_gold_multiplier()
	return 1.0 + (levels.gold or 0) * 0.08
end

function M.get_starting_coins_bonus()
	return (levels.start or 0) * 10
end

-- Persistence
function M.get_save_data()
	return {
		melee = levels.melee or 0,
		archer = levels.archer or 0,
		gold = levels.gold or 0,
		start = levels.start or 0,
	}
end

function M.set_save_data(data)
	if not data then return end
	levels.melee = tonumber(data.melee) or 0
	levels.archer = tonumber(data.archer) or 0
	levels.gold = tonumber(data.gold) or 0
	levels.start = tonumber(data.start) or 0
end

function M.reset()
	levels = { melee = 0, archer = 0, gold = 0, start = 0 }
end

return M
