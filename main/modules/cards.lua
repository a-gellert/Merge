local config = require("main.modules.config")
local grid = require("main.modules.grid")

local M = {}

-- 6 Card Types
M.CARD_UPGRADE = "upgrade" -- +1 Tier on any player squad
M.CARD_CLONE   = "clone"   -- Clone squad to nearest empty cell
M.CARD_MORPH   = "morph"   -- Swap Melee <-> Archer
M.CARD_SHIELD  = "shield"  -- Melee: +25% Max HP shield for the round
M.CARD_FIRE    = "fire"    -- Archer: +30% Damage + fiery trail arrows
M.CARD_RAGE    = "rage"    -- Melee: +40% Attack Speed + +25% Move Speed

M.ALL_CARDS = {
	M.CARD_UPGRADE,
	M.CARD_CLONE,
	M.CARD_MORPH,
	M.CARD_SHIELD,
	M.CARD_FIRE,
	M.CARD_RAGE,
}

-- Card metadata (colors for glow/particles and target requirements)
M.CARD_INFO = {
	[M.CARD_UPGRADE] = {
		glow_color = vmath.vector4(1.0, 0.82, 0.15, 1.0),
		target_role = "any",
	},
	[M.CARD_CLONE] = {
		glow_color = vmath.vector4(0.0, 0.9, 1.0, 1.0),
		target_role = "any",
	},
	[M.CARD_MORPH] = {
		glow_color = vmath.vector4(0.25, 0.95, 0.4, 1.0),
		target_role = "any",
	},
	[M.CARD_SHIELD] = {
		glow_color = vmath.vector4(0.25, 0.65, 1.0, 1.0),
		target_role = config.UNIT_MELEE,
	},
	[M.CARD_FIRE] = {
		glow_color = vmath.vector4(1.0, 0.5, 0.05, 1.0),
		target_role = config.UNIT_ARCHER,
	},
	[M.CARD_RAGE] = {
		glow_color = vmath.vector4(1.0, 0.2, 0.35, 1.0),
		target_role = config.UNIT_MELEE,
	},
}

function M.get_random_card_type()
	local idx = math.random(1, #M.ALL_CARDS)
	return M.ALL_CARDS[idx]
end

-- Check if card can be applied to target squad
function M.can_apply(card_type, squad)
	if not squad or not squad.is_alive then return false end
	if squad.team ~= config.TEAM_PLAYER then return false end
	if squad.is_card or squad.is_crate then return false end

	if card_type == M.CARD_UPGRADE then
		return squad.tier < config.MAX_TIER
	elseif card_type == M.CARD_CLONE then
		-- Clone needs at least one empty cell on the player field
		return grid.find_first_empty_player_cell() ~= nil
	elseif card_type == M.CARD_MORPH then
		return true
	elseif card_type == M.CARD_SHIELD then
		return squad.unit_type == config.UNIT_MELEE
	elseif card_type == M.CARD_FIRE then
		return squad.unit_type == config.UNIT_ARCHER
	elseif card_type == M.CARD_RAGE then
		return squad.unit_type == config.UNIT_MELEE
	end
	return false
end

return M
