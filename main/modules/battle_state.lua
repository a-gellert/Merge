-- Core game state: grid squads, shop, merge, battle simulation and level flow.
-- Pure Lua: every visual side effect goes through view_handlers (battle_manager.script).
local config = require("main.modules.config")
local levels = require("main.modules.levels")
local economy = require("main.modules.economy")
local grid = require("main.modules.grid")
local tutorial = require("main.modules.tutorial")
local poki = require("main.modules.poki")
local storage = require("main.modules.storage")
local cards = require("main.modules.cards")
local projectiles = require("main.modules.projectiles")

local M = {}

local current_level = 1
local phase = config.PHASE_PREP

local player_squads = {}
local enemy_squads = {}
local cards_on_field = {}
local crates_on_field = {}
local rounds_since_crate = 0
local consecutive_losses = 0
local pending_crate = nil -- crate earned on victory, dropped at the start of next level
local next_squad_id = 1
local next_card_id = 1
local next_crate_id = 1

local battle_time = 0
local finale = nil        -- { win = bool, timer = sec } slow-mo outro before result
local time_scale = 1
local last_result = nil
local kill_coins_this_battle = 0

local rage_buff_timer = 0
local RAGE_MAX = 1.4
local RAGE_PER_TAP = 0.35
local RAGE_ATTACK_MULT = 1.25
local RAGE_SPEED_MULT = 1.15

local SUDDEN_DEATH_TIME = 40 -- after this many battle seconds damage ramps up
local KILL_SHARE = 0.45      -- share of level income paid for kills (kept on defeat)
local FINALE_TIME = 1.1      -- seconds of slow-mo after the last squad falls

local view_handlers = {}
local phase_callbacks = {}
local level_callbacks = {}
local new_tier_callbacks = {}

projectiles.init(config.PROJECTILE_POOL_SIZE)

local function view(name, ...)
	local h = view_handlers[name]
	if h then h(...) end
end

function M.set_view_handlers(handlers)
	for k, v in pairs(handlers) do
		view_handlers[k] = v
	end
end

function M.on_phase_change(cb) table.insert(phase_callbacks, cb) end
function M.on_level_change(cb) table.insert(level_callbacks, cb) end
function M.on_new_tier(cb) table.insert(new_tier_callbacks, cb) end

function M.clear_ui_callbacks()
	phase_callbacks = {}
	level_callbacks = {}
	new_tier_callbacks = {}
end

function M.get_current_level() return current_level end
function M.get_phase() return phase end
function M.get_player_squads() return player_squads end
function M.get_enemy_squads() return enemy_squads end
function M.get_cards() return cards_on_field end
function M.get_crates() return crates_on_field end
function M.get_consecutive_losses() return consecutive_losses end
function M.get_last_result() return last_result end
function M.get_time_scale() return time_scale end
function M.get_battle_time() return battle_time end
function M.get_rage_drum_active() return rage_buff_timer > 0 end
function M.get_rage_drum_level() return rage_buff_timer / RAGE_MAX end

-- Enemy HP shrinks a bit after each loss on the same level (hidden pity, min 70%)
local function get_pity_mult()
	return math.max(0.7, 1 - 0.1 * consecutive_losses)
end

local function army_power(list, mult)
	local p = 0
	for i = 1, #list do
		local sq = list[i]
		if sq.is_alive then
			local frac = (phase == config.PHASE_BATTLE) and (sq.hp / sq.max_hp) or 1
			p = p + config.get_squad_power(sq.unit_type, sq.tier) * frac * (mult or 1)
		end
	end
	return p
end

function M.get_player_power() return army_power(player_squads) end
function M.get_enemy_power() return army_power(enemy_squads, get_pity_mult()) end

function M.get_forces_ratio()
	local p, e = 0, 0
	for i = 1, #player_squads do
		local sq = player_squads[i]
		if sq.is_alive then p = p + sq.hp + (sq.shield_hp or 0) end
	end
	for i = 1, #enemy_squads do
		local sq = enemy_squads[i]
		if sq.is_alive then e = e + sq.hp end
	end
	if p + e <= 0 then return 0.5, p, e end
	return p / (p + e), p, e
end

local function set_phase(new_phase)
	phase = new_phase
	view("phase_changed", phase)
	for i = 1, #phase_callbacks do
		phase_callbacks[i](phase)
	end
end

local function build_sub_units(team, count, interval)
	local offsets = config.get_formation_offsets(count)
	local flip = (team == config.TEAM_ENEMY) and -1 or 1
	local subs = {}
	for i = 1, count do
		local o = offsets[i] or vmath.vector3(0, 0, 0.05)
		subs[i] = {
			offset = vmath.vector3(o.x, o.y * flip, o.z),
			attack_timer = math.random() * interval,
		}
	end
	return subs
end

local function apply_stats(sq)
	local stats = config.get_squad_stats(sq.unit_type, sq.tier)
	local hp_mult = (sq.team == config.TEAM_ENEMY) and get_pity_mult() or 1
	sq.max_hp = stats.max_hp * hp_mult
	sq.hp = sq.max_hp
	sq.damage = stats.damage
	sq.attack_interval = stats.attack_interval
	sq.attack_range = stats.attack_range
	sq.speed = stats.speed
	sq.miss_radius = stats.miss_radius
	sq.unit_count = stats.unit_count
	sq.alive_units = stats.unit_count
	sq.per_unit_damage = stats.damage / math.max(1, stats.unit_count)
	sq.sub_units = build_sub_units(sq.team, stats.unit_count, stats.attack_interval)
	sq.power = config.get_squad_power(sq.unit_type, sq.tier)
end

local function create_squad_data(team, unit_type, tier, row, col)
	local home_pos = grid.get_cell_pos(team, row, col)
	local squad = {
		id = next_squad_id,
		team = team,
		unit_type = unit_type,
		tier = tier,
		row = row,
		col = col,
		home_pos = vmath.vector3(home_pos),
		current_pos = vmath.vector3(home_pos),
		attack_timer = 0,
		target = nil,
		is_alive = true,
		go_id = nil,
	}
	next_squad_id = next_squad_id + 1
	apply_stats(squad)
	return squad
end

local function clear_buffs(sq)
	sq.has_shield, sq.shield_hp, sq.has_fire, sq.has_rage = nil, nil, nil, nil
end

local function track_tier(tier, pos)
	if economy.register_tier(tier) and tier >= 3 then
		view("play_effect", "new_tier", pos, { tier = tier })
		for i = 1, #new_tier_callbacks do
			new_tier_callbacks[i](tier)
		end
	end
end

local function add_player_squad(unit_type, tier, r, c, is_merge)
	local squad = create_squad_data(config.TEAM_PLAYER, unit_type, tier, r, c)
	squad.is_merge = is_merge
	table.insert(player_squads, squad)
	grid.set_player_squad(r, c, squad)
	view("spawn_squad", squad)
	track_tier(tier, squad.home_pos)
	return squad
end

local function remove_player_squad(squad)
	for i = #player_squads, 1, -1 do
		if player_squads[i].id == squad.id then
			table.remove(player_squads, i)
			break
		end
	end
end

-- Melee fill the front rows first, archers the back rows; center columns first
local COL_ORDER = { 2, 3, 1, 4 }
function M.find_spawn_cell(unit_type)
	local r_from, r_to, r_step = 4, 1, -1
	if unit_type == config.UNIT_ARCHER then
		r_from, r_to, r_step = 1, 4, 1
	end
	for r = r_from, r_to, r_step do
		for _, c in ipairs(COL_ORDER) do
			if grid.get_player_item(r, c) == nil then
				return r, c
			end
		end
	end
	return nil, nil
end

function M.has_free_cell()
	return grid.find_first_empty_player_cell() ~= nil
end

-- =============================================================================
-- CARDS & CRATES
-- =============================================================================
function M.spawn_card(card_type, r, c)
	local home_pos = grid.get_cell_pos(config.TEAM_PLAYER, r, c)
	local card_item = {
		id = next_card_id,
		is_card = true,
		card_type = card_type,
		row = r,
		col = c,
		home_pos = vmath.vector3(home_pos),
		current_pos = vmath.vector3(home_pos),
	}
	next_card_id = next_card_id + 1
	table.insert(cards_on_field, card_item)
	grid.set_player_item(r, c, card_item)
	view("spawn_card", card_item)
	return card_item
end

function M.spawn_drop_crate(r, c, forced_card_type, is_golden)
	local home_pos = grid.get_cell_pos(config.TEAM_PLAYER, r, c)
	local crate_item = {
		id = next_crate_id,
		is_crate = true,
		row = r,
		col = c,
		forced_card_type = forced_card_type,
		is_golden = is_golden,
		home_pos = vmath.vector3(home_pos),
		current_pos = vmath.vector3(home_pos),
	}
	next_crate_id = next_crate_id + 1
	table.insert(crates_on_field, crate_item)
	grid.set_player_item(r, c, crate_item)
	view("spawn_crate", crate_item)
	return crate_item
end

function M.try_spawn_pity_crate()
	if consecutive_losses < 2 then return false end
	local r, c = grid.find_first_empty_player_cell()
	if not r then return false end
	M.spawn_drop_crate(r, c, cards.CARD_UPGRADE, true)
	return true
end

function M.open_crate(crate_item)
	if not crate_item or not crate_item.is_crate then return false end
	grid.set_player_item(crate_item.row, crate_item.col, nil)
	for i = #crates_on_field, 1, -1 do
		if crates_on_field[i].id == crate_item.id then
			table.remove(crates_on_field, i)
			break
		end
	end
	local r, c = crate_item.row, crate_item.col
	local card_type = crate_item.forced_card_type or cards.get_random_card_type()
	local spawn = function()
		if grid.get_player_item(r, c) == nil then
			M.spawn_card(card_type, r, c)
			M.save_game()
		end
	end
	view("play_effect", "crate_open", crate_item.home_pos, { golden = crate_item.is_golden })
	if view_handlers.despawn_crate then
		view_handlers.despawn_crate(crate_item, spawn)
	else
		spawn()
	end
	return true
end

function M.apply_card(card_item, target)
	if not cards.can_apply(card_item.card_type, target) then
		return false
	end

	grid.set_player_item(card_item.row, card_item.col, nil)
	for i = #cards_on_field, 1, -1 do
		if cards_on_field[i].id == card_item.id then
			table.remove(cards_on_field, i)
			break
		end
	end
	view("despawn_card", card_item)

	local ctype = card_item.card_type
	if ctype == cards.CARD_UPGRADE then
		target.tier = math.min(config.MAX_TIER, target.tier + 1)
		apply_stats(target)
		target.is_merge = true
		view("refresh_squad", target)
		view("play_effect", "merge", target.home_pos, { tier = target.tier })
		track_tier(target.tier, target.home_pos)
	elseif ctype == cards.CARD_CLONE then
		local r, c = grid.find_first_empty_player_cell()
		if r then
			local clone = add_player_squad(target.unit_type, target.tier, r, c, true)
			view("play_effect", "merge", clone.home_pos, { tier = clone.tier })
		end
	elseif ctype == cards.CARD_MORPH then
		target.unit_type = (target.unit_type == config.UNIT_MELEE) and config.UNIT_ARCHER or config.UNIT_MELEE
		apply_stats(target)
		target.is_merge = true
		view("refresh_squad", target)
		view("play_effect", "merge", target.home_pos, { tier = target.tier })
	elseif ctype == cards.CARD_SHIELD then
		target.shield_hp = (target.shield_hp or 0) + target.max_hp * 0.4
		target.has_shield = true
		view("squad_buff", target, "shield", true)
	elseif ctype == cards.CARD_FIRE then
		target.damage = target.damage * 1.4
		target.per_unit_damage = target.damage / math.max(1, target.unit_count)
		target.has_fire = true
		view("squad_buff", target, "fire", true)
	elseif ctype == cards.CARD_RAGE then
		target.attack_interval = target.attack_interval * 0.7
		target.speed = target.speed * 1.25
		target.has_rage = true
		view("squad_buff", target, "rage", true)
	end

	M.save_game()
	return true
end

function M.move_card(card_item, to_r, to_c)
	if phase ~= config.PHASE_PREP then return false end
	if card_item.row == to_r and card_item.col == to_c then return false end

	local existing = grid.get_player_item(to_r, to_c)
	if existing then
		if not existing.is_card and not existing.is_crate then
			return M.apply_card(card_item, existing)
		end
		local from_r, from_c = card_item.row, card_item.col
		grid.set_player_item(from_r, from_c, existing)
		grid.set_player_item(to_r, to_c, card_item)
		view("snap_item", card_item)
		view("snap_item", existing)
	else
		grid.set_player_item(card_item.row, card_item.col, nil)
		grid.set_player_item(to_r, to_c, card_item)
		view("snap_item", card_item)
	end
	M.save_game()
	return true
end

-- =============================================================================
-- SAVE / LOAD
-- =============================================================================
function M.save_game()
	local squads_save = {}
	for _, sq in ipairs(player_squads) do
		table.insert(squads_save, { unit_type = sq.unit_type, tier = sq.tier, row = sq.row, col = sq.col })
	end
	local cards_save = {}
	for _, c in ipairs(cards_on_field) do
		table.insert(cards_save, { card_type = c.card_type, row = c.row, col = c.col })
	end
	local crates_save = {}
	for _, cr in ipairs(crates_on_field) do
		table.insert(crates_save, { row = cr.row, col = cr.col, card_type = cr.forced_card_type, golden = cr.is_golden })
	end
	storage.save({
		version = 2,
		level = current_level,
		coins = economy.get_coins(),
		best_tier = economy.get_best_tier(),
		level_buys = economy.get_level_buys(),
		tutorial_done = tutorial.is_completed(),
		rounds_since_crate = rounds_since_crate,
		consecutive_losses = consecutive_losses,
		player_squads = squads_save,
		cards = cards_save,
		crates = crates_save,
	})
end

function M.load_game()
	local data = storage.load()
	if not data or data.version ~= 2 then return false end

	current_level = tonumber(data.level) or 1
	rounds_since_crate = tonumber(data.rounds_since_crate) or 0
	consecutive_losses = tonumber(data.consecutive_losses) or 0
	economy.set_state(data.coins, data.best_tier, data.level_buys)
	if data.tutorial_done then
		tutorial.set_completed(true)
	end

	for i = 1, #player_squads do view("despawn_squad", player_squads[i], "remove") end
	for i = 1, #cards_on_field do view("despawn_card", cards_on_field[i]) end
	for i = 1, #crates_on_field do view("despawn_crate", crates_on_field[i]) end
	player_squads, cards_on_field, crates_on_field = {}, {}, {}
	grid.clear_player_cells()

	for _, s in ipairs(data.player_squads or {}) do
		local squad = create_squad_data(config.TEAM_PLAYER, s.unit_type, s.tier, s.row, s.col)
		table.insert(player_squads, squad)
		grid.set_player_squad(s.row, s.col, squad)
		view("spawn_squad", squad)
	end
	for _, c in ipairs(data.cards or {}) do
		M.spawn_card(c.card_type, c.row, c.col)
	end
	for _, cr in ipairs(data.crates or {}) do
		M.spawn_drop_crate(cr.row, cr.col, cr.card_type, cr.golden)
	end
	return true
end

-- =============================================================================
-- LEVEL FLOW
-- =============================================================================
-- is_resume: continuing a saved session (no new loot, keeps per-level shop prices)
function M.start_level(level_num, is_retry, is_resume)
	current_level = level_num or current_level
	rage_buff_timer = 0
	battle_time = 0
	finale = nil
	time_scale = 1
	projectiles.clear()
	if not is_retry and not is_resume then
		economy.new_level()
	end
	set_phase(config.PHASE_PREP)

	for i = 1, #enemy_squads do
		view("despawn_squad", enemy_squads[i], "remove")
	end
	enemy_squads = {}
	grid.clear_enemy_cells()

	-- Everyone comes back to full strength at home; one-battle card buffs expire
	for i = 1, #player_squads do
		local sq = player_squads[i]
		local was_dead = not sq.is_alive
		clear_buffs(sq)
		apply_stats(sq)
		sq.is_alive = true
		sq.engaged = false
		sq.current_pos = vmath.vector3(sq.home_pos)
		sq.target = nil
		if was_dead or not sq.go_id then
			view("spawn_squad", sq)
		else
			view("replenish_squad", sq)
		end
	end

	local level_data = levels.get_level(current_level)

	if current_level == 1 and #player_squads == 0 and level_data.initial_player then
		for _, p in ipairs(level_data.initial_player) do
			add_player_squad(p.unit_type, p.tier, p.row, p.col)
		end
	end

	-- Loot: crate earned last level, or pity crate after repeated losses
	if is_resume then
		-- nothing: crates and cards were restored from the save
	elseif pending_crate and not is_retry then
		local r, c = grid.find_first_empty_player_cell()
		if r then
			M.spawn_drop_crate(r, c, pending_crate.card_type, pending_crate.golden)
		end
		pending_crate = nil
	elseif is_retry then
		M.try_spawn_pity_crate()
	end

	-- Enemy army; kill coins are spread by power share
	local income = level_data.income
	local total_power = 0
	for _, e in ipairs(level_data.enemies) do
		total_power = total_power + config.get_squad_power(e.unit_type, e.tier)
	end
	for _, e in ipairs(level_data.enemies) do
		local sq = create_squad_data(config.TEAM_ENEMY, e.unit_type, e.tier, e.row, e.col)
		sq.is_boss = e.is_boss
		sq.coin_value = income * KILL_SHARE * sq.power / math.max(1, total_power)
		table.insert(enemy_squads, sq)
		grid.set_enemy_squad(e.row, e.col, sq)
		view("spawn_squad", sq)
	end

	tutorial.init_for_level(current_level)
	poki.measure("level", tostring(current_level), "start")

	view("level_changed", current_level)
	for i = 1, #level_callbacks do
		level_callbacks[i](current_level)
	end
	M.save_game()
end

function M.get_win_reward()
	return levels.get_income(current_level) * (1 - KILL_SHARE)
end

-- No result screens: a win starts the next level, a loss restarts this one
function M.claim_victory()
	if phase ~= config.PHASE_VICTORY then return false end
	consecutive_losses = 0
	current_level = current_level + 1
	M.start_level(current_level, false)
	return true
end

function M.retry()
	if phase ~= config.PHASE_DEFEAT then return false end
	M.start_level(current_level, true)
	return true
end

-- Free squad (rewarded ad). If the grid is full, the weakest squad gets +1 tier instead.
function M.grant_free_squad(tier, unit_type)
	if phase ~= config.PHASE_PREP then return false end
	tier = tier or (economy.get_shop_tier() + 1)
	if not unit_type then
		local melee, archer = 0, 0
		for _, sq in ipairs(player_squads) do
			if sq.unit_type == config.UNIT_MELEE then melee = melee + 1 else archer = archer + 1 end
		end
		unit_type = (archer * 1.5 < melee) and config.UNIT_ARCHER or config.UNIT_MELEE
	end
	local r, c = M.find_spawn_cell(unit_type)
	if r then
		local sq = add_player_squad(unit_type, tier, r, c, true)
		view("play_effect", "lucky", sq.home_pos, { tier = tier })
	else
		local weakest
		for _, sq in ipairs(player_squads) do
			if not weakest or sq.tier < weakest.tier then weakest = sq end
		end
		if not weakest then return false end
		weakest.tier = weakest.tier + 1
		apply_stats(weakest)
		weakest.is_merge = true
		view("refresh_squad", weakest)
		view("play_effect", "merge", weakest.home_pos, { tier = weakest.tier })
		track_tier(weakest.tier, weakest.home_pos)
	end
	M.save_game()
	return true
end

-- =============================================================================
-- SHOP & MERGE
-- =============================================================================
function M.buy_unit(unit_type)
	if phase ~= config.PHASE_PREP then return false end
	unit_type = unit_type or config.UNIT_MELEE
	if not economy.can_afford_buy() then return false end

	local tut_buy = tutorial.get_step() == tutorial.STEP_BUY
	if tut_buy then unit_type = config.UNIT_MELEE end

	local r, c = M.find_spawn_cell(unit_type)
	if not r then return false end
	if not economy.spend_for_buy() then return false end

	local tier = economy.get_shop_tier()
	local lucky = (not tut_buy) and current_level > 2 and math.random() < config.SHOP_LUCKY_CHANCE
	if lucky then tier = tier + 1 end

	local squad = add_player_squad(unit_type, tier, r, c)
	if lucky then
		view("play_effect", "lucky", squad.home_pos, { tier = tier })
	end

	tutorial.advance_from_buy()
	M.save_game()
	return true, squad
end

function M.merge_units(from_r, from_c, to_r, to_c)
	if phase ~= config.PHASE_PREP then return false end
	if from_r == to_r and from_c == to_c then return false end

	local a = grid.get_player_squad(from_r, from_c)
	local b = grid.get_player_squad(to_r, to_c)
	if not a or not b then return false end

	if a.unit_type ~= b.unit_type or a.tier ~= b.tier or a.tier >= config.MAX_TIER then
		-- Not mergeable: swap places
		grid.set_player_squad(from_r, from_c, b)
		grid.set_player_squad(to_r, to_c, a)
		a.current_pos = vmath.vector3(a.home_pos)
		b.current_pos = vmath.vector3(b.home_pos)
		view("snap_squad", a)
		view("snap_squad", b)
		M.save_game()
		return true
	end

	grid.set_player_squad(from_r, from_c, nil)
	grid.set_player_squad(to_r, to_c, nil)
	a.is_alive = false
	b.is_alive = false
	view("despawn_squad", a, "merge")
	view("despawn_squad", b, "merge")
	remove_player_squad(a)
	remove_player_squad(b)

	local merged = add_player_squad(a.unit_type, a.tier + 1, to_r, to_c, true)
	view("play_effect", "merge", merged.home_pos, { tier = merged.tier, unit_type = merged.unit_type })

	tutorial.advance_from_merge()
	M.save_game()
	return true
end

function M.find_merge_pair()
	local best_a, best_b
	for i = 1, #player_squads do
		local s1 = player_squads[i]
		if s1.is_alive and s1.tier < config.MAX_TIER then
			for j = i + 1, #player_squads do
				local s2 = player_squads[j]
				if s2.is_alive and s2.tier == s1.tier and s2.unit_type == s1.unit_type then
					if not best_a or s1.tier < best_a.tier then
						best_a, best_b = s1, s2
					end
				end
			end
		end
	end
	return best_a, best_b
end

function M.can_auto_merge()
	if phase ~= config.PHASE_PREP then return false end
	return M.find_merge_pair() ~= nil
end

-- Merge every available pair (lowest tiers first, cascades included).
-- The squad closer to the front keeps the cell.
function M.auto_merge()
	if phase ~= config.PHASE_PREP then return false end
	local merged_any = false
	for _ = 1, 32 do
		local a, b = M.find_merge_pair()
		if not a then break end
		local front_is_b = (b.unit_type == config.UNIT_MELEE) == (b.row >= a.row)
		if front_is_b then
			M.merge_units(a.row, a.col, b.row, b.col)
		else
			M.merge_units(b.row, b.col, a.row, a.col)
		end
		merged_any = true
	end
	return merged_any
end

function M.move_squad(from_r, from_c, to_r, to_c)
	if phase ~= config.PHASE_PREP then return false end
	local squad = grid.get_player_squad(from_r, from_c)
	if not squad then return false end

	local existing = grid.get_player_item(to_r, to_c)
	if existing then
		if existing.is_card or existing.is_crate then
			grid.set_player_item(from_r, from_c, existing)
			grid.set_player_item(to_r, to_c, squad)
			squad.current_pos = vmath.vector3(squad.home_pos)
			view("snap_squad", squad)
			view("snap_item", existing)
			M.save_game()
			return true
		end
		return M.merge_units(from_r, from_c, to_r, to_c)
	end

	grid.set_player_item(from_r, from_c, nil)
	grid.set_player_item(to_r, to_c, squad)
	squad.current_pos = vmath.vector3(squad.home_pos)
	view("snap_squad", squad)
	M.save_game()
	return true
end

function M.get_sell_price(item)
	if not item then return 0 end
	local value = item.tier and config.get_tier_value(item.tier) or config.get_tier_value(economy.get_shop_tier())
	return math.max(1, math.floor(config.PRICE_BASE * value * 0.5 + 0.5))
end

function M.sell_squad(squad)
	if phase ~= config.PHASE_PREP then return false end
	if not squad or not squad.is_alive then return false end
	local price = M.get_sell_price(squad)
	local sell_pos = vmath.vector3(config.TRASH_BIN_POS)

	grid.set_player_squad(squad.row, squad.col, nil)
	squad.is_alive = false
	remove_player_squad(squad)
	view("sell_item", squad, sell_pos)
	economy.add_coins(price, sell_pos)
	view("play_effect", "sell", sell_pos, { price = price })
	M.save_game()
	return true
end

function M.sell_card(card_item)
	if phase ~= config.PHASE_PREP then return false end
	if not card_item then return false end
	local price = M.get_sell_price(card_item)
	local sell_pos = vmath.vector3(config.TRASH_BIN_POS)

	grid.set_player_item(card_item.row, card_item.col, nil)
	for i = #cards_on_field, 1, -1 do
		if cards_on_field[i].id == card_item.id then
			table.remove(cards_on_field, i)
			break
		end
	end
	view("sell_item", card_item, sell_pos)
	economy.add_coins(price, sell_pos)
	view("play_effect", "sell", sell_pos, { price = price })
	M.save_game()
	return true
end

-- =============================================================================
-- BATTLE
-- =============================================================================
function M.tap_battle_drum(tap_pos)
	if phase ~= config.PHASE_BATTLE or finale then return false end
	rage_buff_timer = math.min(RAGE_MAX, rage_buff_timer + RAGE_PER_TAP)
	if tap_pos then
		view("play_effect", "drum_tap", tap_pos)
	end
	return true
end

local function prime_squad(sq)
	sq.current_pos = vmath.vector3(sq.home_pos)
	sq.target = nil
	sq.engaged = false
	for idx, u in ipairs(sq.sub_units) do
		u.attack_timer = (idx - 1) * 0.05 + math.random() * 0.25
	end
end

function M.start_battle()
	if phase ~= config.PHASE_PREP then return false end
	if #player_squads == 0 then return false end

	poki.gameplay_start()
	tutorial.advance_from_battle()
	last_result = nil
	battle_time = 0
	kill_coins_this_battle = 0
	finale = nil
	time_scale = 1
	set_phase(config.PHASE_BATTLE)

	for _, sq in ipairs(player_squads) do prime_squad(sq) end
	for _, sq in ipairs(enemy_squads) do prime_squad(sq) end
	view("play_effect", "battle_start", vmath.vector3(200, 322, 0))
	return true
end

local function find_nearest_target(squad, opponents)
	local best, best_d2 = nil, math.huge
	local sx, sy = squad.current_pos.x, squad.current_pos.y
	for i = 1, #opponents do
		local opp = opponents[i]
		if opp.is_alive then
			local dx = opp.current_pos.x - sx
			local dy = opp.current_pos.y - sy
			local d2 = dx * dx + dy * dy
			if d2 < best_d2 then
				best_d2 = d2
				best = opp
			end
		end
	end
	return best
end

local function apply_friendly_separation(squad, allies, dt)
	local sx, sy = squad.current_pos.x, squad.current_pos.y
	local r_repel = config.SQUAD_RADIUS * 2
	local r2 = r_repel * r_repel
	for i = 1, #allies do
		local ally = allies[i]
		if ally ~= squad and ally.is_alive then
			local dx = sx - ally.current_pos.x
			local dy = sy - ally.current_pos.y
			local d2 = dx * dx + dy * dy
			if d2 < r2 and d2 > 0.001 then
				local dist = math.sqrt(d2)
				local push = (r_repel - dist) / r_repel * config.REPEL_FORCE * dt
				squad.current_pos.x = squad.current_pos.x + (dx / dist) * push
				squad.current_pos.y = squad.current_pos.y + (dy / dist) * push
			end
		end
	end
end

function M.apply_damage(squad, amount, hit_x, hit_y)
	if not squad.is_alive or amount <= 0 then return end

	if squad.shield_hp and squad.shield_hp > 0 then
		local absorbed = math.min(squad.shield_hp, amount)
		squad.shield_hp = squad.shield_hp - absorbed
		amount = amount - absorbed
		if squad.shield_hp <= 0 then
			squad.has_shield = false
			view("squad_buff", squad, "shield", false)
		end
		if amount <= 0 then return end
	end

	local prev_alive = squad.alive_units
	squad.hp = math.max(0, squad.hp - amount)
	local new_alive = 0
	if squad.hp > 0 then
		new_alive = math.max(1, math.ceil(squad.hp / squad.max_hp * squad.unit_count))
	end
	squad.alive_units = new_alive
	local killed = prev_alive - new_alive

	if squad.team == config.TEAM_ENEMY and killed > 0 and squad.coin_value then
		local reward = squad.coin_value * killed / squad.unit_count
		kill_coins_this_battle = kill_coins_this_battle + reward
		economy.add_coins(reward, vmath.vector3(squad.current_pos))
	end

	view("damage_squad", squad, amount, killed, hit_x, hit_y)

	if squad.hp <= 0 then
		squad.is_alive = false
		squad.alive_units = 0
		view("play_effect", "squad_death", vmath.vector3(squad.current_pos), {
			tier = squad.tier, team = squad.team, is_boss = squad.is_boss,
		})
		view("despawn_squad", squad, "dead")
	end
end

local function on_arrow_hit(target, damage, x, y, is_fire)
	M.apply_damage(target, damage, x, y)
	view("play_effect", "arrow_hit", vmath.vector3(x, y, 0), { team = target.team, fire = is_fire })
end

local function count_alive(list)
	local n = 0
	for i = 1, #list do
		if list[i].is_alive then n = n + 1 end
	end
	return n
end

local function finish_battle(win)
	time_scale = 1
	finale = nil
	projectiles.clear()
	poki.gameplay_stop()
	last_result = {
		win = win,
		level = current_level,
		kill_coins = kill_coins_this_battle,
		win_reward = win and M.get_win_reward() or 0,
		is_boss = levels.is_boss(current_level),
	}
	if win then
		poki.measure("level", tostring(current_level), "complete")
		rounds_since_crate = rounds_since_crate + 1
		if levels.is_boss(current_level) or levels.is_mini_boss(current_level) then
			pending_crate = { card_type = cards.CARD_UPGRADE, golden = true }
			last_result.chest = "golden"
		elseif rounds_since_crate >= 3 then
			rounds_since_crate = 0
			pending_crate = {}
			last_result.chest = "wood"
		end
		economy.add_coins(last_result.win_reward, vmath.vector3(200, 450, 0))
		set_phase(config.PHASE_VICTORY)
	else
		poki.measure("level", tostring(current_level), "fail")
		consecutive_losses = consecutive_losses + 1
		set_phase(config.PHASE_DEFEAT)
	end
	M.save_game()
	-- Natural break for an interstitial, then straight into the next (or same) level
	poki.level_break(current_level, function()
		if win then M.claim_victory() else M.retry() end
	end)
end

function M.update_battle(real_dt)
	if phase ~= config.PHASE_BATTLE then return end

	-- Slow-mo finale after the last squad falls
	if finale then
		finale.timer = finale.timer - real_dt
		time_scale = math.min(1, time_scale + real_dt * 0.6)
		if finale.timer <= 0 then
			finish_battle(finale.win)
			return
		end
	end

	local dt = real_dt * time_scale
	battle_time = battle_time + dt

	if not finale then
		local p_alive = count_alive(player_squads)
		local e_alive = count_alive(enemy_squads)
		if e_alive == 0 or p_alive == 0 then
			local win = (e_alive == 0)
			finale = { win = win, timer = FINALE_TIME }
			time_scale = 0.3
			view("play_effect", win and "victory_burst" or "defeat_burst", vmath.vector3(200, 322, 0))
		end
	end

	if rage_buff_timer > 0 then
		rage_buff_timer = math.max(0, rage_buff_timer - dt)
	end
	local drum = rage_buff_timer > 0
	local overtime = 1
	if battle_time > SUDDEN_DEATH_TIME then
		overtime = 1 + (battle_time - SUDDEN_DEATH_TIME) * 0.15
	end

	projectiles.update(dt, on_arrow_hit)

	for g = 1, 2 do
		local list = (g == 1) and player_squads or enemy_squads
		local foes = (g == 1) and enemy_squads or player_squads
		local is_player = (g == 1)
		local atk_mult = (is_player and drum) and RAGE_ATTACK_MULT or 1
		local spd_mult = (is_player and drum) and RAGE_SPEED_MULT or 1

		for _, squad in ipairs(list) do
			if squad.is_alive then
				if not squad.target or not squad.target.is_alive then
					squad.target = find_nearest_target(squad, foes)
				end

				local tgt = squad.target
				if tgt then
					local dx = tgt.current_pos.x - squad.current_pos.x
					local dy = tgt.current_pos.y - squad.current_pos.y
					local dist = math.sqrt(dx * dx + dy * dy)

					if dist > squad.attack_range then
						local step = math.min(dist - squad.attack_range * 0.9, squad.speed * spd_mult * dt)
						squad.current_pos.x = squad.current_pos.x + (dx / dist) * step
						squad.current_pos.y = squad.current_pos.y + (dy / dist) * step
					else
						if not squad.engaged then
							squad.engaged = true
							if squad.unit_type == config.UNIT_MELEE and is_player then
								view("play_effect", "clash", vmath.vector3(
									(squad.current_pos.x + tgt.current_pos.x) * 0.5,
									(squad.current_pos.y + tgt.current_pos.y) * 0.5, 0), { tier = squad.tier })
							end
						end
						local active = math.min(squad.alive_units, squad.unit_count)
						local unit_dmg = squad.per_unit_damage * overtime
						local swung = false
						for u_idx = 1, active do
							local u = squad.sub_units[u_idx]
							u.attack_timer = u.attack_timer - dt * atk_mult
							if u.attack_timer <= 0 then
								u.attack_timer = squad.attack_interval / atk_mult + (math.random() - 0.5) * 0.12
								if squad.unit_type == config.UNIT_ARCHER then
									projectiles.spawn(
										squad.current_pos.x + u.offset.x,
										squad.current_pos.y + u.offset.y,
										tgt, unit_dmg, squad.miss_radius, squad.has_fire, squad.team)
								else
									M.apply_damage(tgt, unit_dmg)
									swung = true
								end
								if not tgt.is_alive then break end
							end
						end
						if swung then
							view("attack_squad", squad, tgt)
						end
					end
				end

				apply_friendly_separation(squad, list, dt)
				squad.current_pos.x = math.max(config.ARENA_MIN_X, math.min(config.ARENA_MAX_X, squad.current_pos.x))
				squad.current_pos.y = math.max(config.ARENA_MIN_Y, math.min(config.ARENA_MAX_Y, squad.current_pos.y))
				view("update_squad", squad)
			end
		end
	end
end

-- Debug only (merge.start_level): jump to a level with an army that matches the curve
function M.debug_setup(level)
	local top = math.max(1, math.floor(levels.target_tier(level)))
	economy.register_tier(top)
	tutorial.set_completed(true)
	current_level = level
	local plan = { top, top - 1, top - 1, top - 2, top - 2, top - 2, top - 3, top - 3, top - 3, top - 3 }
	for i, t in ipairs(plan) do
		local unit_type = (i % 3 == 0) and config.UNIT_ARCHER or config.UNIT_MELEE
		local r, c = M.find_spawn_cell(unit_type)
		if r and t >= 1 then
			add_player_squad(unit_type, t, r, c)
		end
	end
	M.start_level(level)
end

return M
