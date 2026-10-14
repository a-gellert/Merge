local config = require("main.modules.config")
local levels = require("main.modules.levels")
local economy = require("main.modules.economy")
local grid = require("main.modules.grid")
local tutorial = require("main.modules.tutorial")
local poki = require("main.modules.poki")
local storage = require("main.modules.storage")
local cards = require("main.modules.cards")

local M = {}

local current_level = 1
local phase = config.PHASE_PREP

local player_squads = {}
local enemy_squads = {}
local cards_on_field = {}
local crates_on_field = {}
local rounds_since_crate = 0
local next_squad_id = 1
local next_card_id = 1
local next_crate_id = 1

local view_handlers = {
	spawn_squad = nil,
	despawn_squad = nil,
	update_squad = nil,
	replenish_squad = nil,
	snap_squad = nil,
	damage_squad = nil,
	attack_squad = nil,
	phase_changed = nil,
	level_changed = nil,
	shoot_projectile = nil,
	play_effect = nil,
	spawn_card = nil,
	despawn_card = nil,
	spawn_crate = nil,
	despawn_crate = nil,
}

local phase_callbacks = {}
local level_callbacks = {}

function M.set_view_handlers(handlers)
	for k, v in pairs(handlers) do
		view_handlers[k] = v
	end
end

function M.on_phase_change(cb)
	table.insert(phase_callbacks, cb)
end

function M.on_level_change(cb)
	table.insert(level_callbacks, cb)
end

function M.clear_ui_callbacks()
	phase_callbacks = {}
	level_callbacks = {}
end

function M.get_current_level()
	return current_level
end

function M.get_phase()
	return phase
end

function M.get_player_squads()
	return player_squads
end

function M.get_enemy_squads()
	return enemy_squads
end

function M.get_cards()
	return cards_on_field
end

function M.get_crates()
	return crates_on_field
end

local function set_phase(new_phase)
	phase = new_phase
	if view_handlers.phase_changed then
		view_handlers.phase_changed(phase)
	end
	for i = 1, #phase_callbacks do
		phase_callbacks[i](phase)
	end
end

local function create_squad_data(team, unit_type, tier, row, col)
	local stats = config.get_squad_stats(unit_type, tier)
	local home_pos = grid.get_cell_pos(team, row, col)
	local id = next_squad_id
	next_squad_id = next_squad_id + 1

	local offsets = config.get_formation_offsets(stats.unit_count)
	local sub_units = {}
	for i = 1, stats.unit_count do
		table.insert(sub_units, {
			offset = offsets[i] or vmath.vector3(0, 0, 0),
			attack_timer = math.random() * stats.attack_interval,
		})
	end

	local squad = {
		id = id,
		team = team,
		unit_type = unit_type,
		tier = tier,
		row = row,
		col = col,
		home_pos = vmath.vector3(home_pos),
		current_pos = vmath.vector3(home_pos),
		hp = stats.max_hp,
		max_hp = stats.max_hp,
		damage = stats.damage,
		per_unit_damage = stats.damage / math.max(1, stats.unit_count),
		attack_interval = stats.attack_interval,
		attack_range = stats.attack_range,
		speed = stats.speed,
		miss_radius = stats.miss_radius,
		unit_count = stats.unit_count,
		alive_units = stats.unit_count,
		sub_units = sub_units,
		attack_timer = math.random() * 0.3,
		target = nil,
		is_alive = true,
		go_id = nil,
	}
	return squad
end

local function refresh_squad_stats(sq)
	local stats = config.get_squad_stats(sq.unit_type, sq.tier)
	sq.hp = stats.max_hp
	sq.max_hp = stats.max_hp
	sq.damage = stats.damage
	sq.per_unit_damage = stats.damage / math.max(1, stats.unit_count)
	sq.attack_interval = stats.attack_interval
	sq.attack_range = stats.attack_range
	sq.speed = stats.speed
	sq.miss_radius = stats.miss_radius
	sq.unit_count = stats.unit_count
	sq.alive_units = stats.unit_count

	local offsets = config.get_formation_offsets(stats.unit_count)
	sq.sub_units = {}
	for i = 1, stats.unit_count do
		table.insert(sq.sub_units, {
			offset = offsets[i] or vmath.vector3(0, 0, 0),
			attack_timer = math.random() * stats.attack_interval,
		})
	end

	if sq.go_id and go.exists(sq.go_id) then
		msg.post(sq.go_id, "setup", {
			team = sq.team,
			unit_type = sq.unit_type,
			tier = sq.tier,
			unit_count = sq.unit_count,
			pos = sq.home_pos,
			is_merge = true,
		})
	end
end
M.refresh_squad_stats = refresh_squad_stats

function M.create_player_squad(unit_type, tier, r, c)
	local squad = create_squad_data(config.TEAM_PLAYER, unit_type, tier, r, c)
	table.insert(player_squads, squad)
	grid.set_player_squad(r, c, squad)
	if view_handlers.spawn_squad then
		view_handlers.spawn_squad(squad)
	end
	M.save_game()
	return squad
end

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
		go_id = nil,
	}
	next_card_id = next_card_id + 1
	table.insert(cards_on_field, card_item)
	grid.set_player_item(r, c, card_item)

	if view_handlers.spawn_card then
		view_handlers.spawn_card(card_item)
	end
	M.save_game()
	return card_item
end

function M.spawn_drop_crate(r, c)
	local home_pos = grid.get_cell_pos(config.TEAM_PLAYER, r, c)
	local crate_item = {
		id = next_crate_id,
		is_crate = true,
		row = r,
		col = c,
		home_pos = vmath.vector3(home_pos),
		current_pos = vmath.vector3(home_pos),
		go_id = nil,
	}
	next_crate_id = next_crate_id + 1
	table.insert(crates_on_field, crate_item)
	grid.set_player_item(r, c, crate_item)

	if view_handlers.spawn_crate then
		view_handlers.spawn_crate(crate_item)
	end
	M.save_game()
	return crate_item
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

	local r = crate_item.row
	local c = crate_item.col
	if view_handlers.despawn_crate then
		view_handlers.despawn_crate(crate_item, function()
			local card_type = cards.get_random_card_type()
			M.spawn_card(card_type, r, c)
		end)
	else
		local card_type = cards.get_random_card_type()
		M.spawn_card(card_type, r, c)
	end
	return true
end

function M.apply_card(card_item, target_squad)
	if not cards.can_apply(card_item.card_type, target_squad) then
		return false
	end

	grid.set_player_item(card_item.row, card_item.col, nil)
	for i = #cards_on_field, 1, -1 do
		if cards_on_field[i].id == card_item.id then
			table.remove(cards_on_field, i)
			break
		end
	end

	if view_handlers.despawn_card then
		view_handlers.despawn_card(card_item)
	end

	local ctype = card_item.card_type
	if ctype == cards.CARD_UPGRADE then
		target_squad.tier = math.min(config.MAX_TIER, target_squad.tier + 1)
		refresh_squad_stats(target_squad)
		if view_handlers.play_effect then
			view_handlers.play_effect("merge", target_squad.home_pos, { tier = target_squad.tier })
		end
	elseif ctype == cards.CARD_CLONE then
		local empty_r, empty_c = grid.find_first_empty_player_cell()
		if empty_r and empty_c then
			local clone_squad = M.create_player_squad(target_squad.unit_type, target_squad.tier, empty_r, empty_c)
			clone_squad.is_merge = true
			if view_handlers.play_effect then
				view_handlers.play_effect("merge", clone_squad.home_pos, { tier = clone_squad.tier })
			end
		end
	elseif ctype == cards.CARD_MORPH then
		target_squad.unit_type = (target_squad.unit_type == config.UNIT_MELEE) and config.UNIT_ARCHER or config.UNIT_MELEE
		refresh_squad_stats(target_squad)
		if view_handlers.play_effect then
			view_handlers.play_effect("merge", target_squad.home_pos, { tier = target_squad.tier })
		end
	elseif ctype == cards.CARD_SHIELD then
		local shield_val = math.floor(target_squad.max_hp * 0.25)
		target_squad.shield_hp = (target_squad.shield_hp or 0) + shield_val
		target_squad.has_shield = true
		if target_squad.go_id then
			msg.post(target_squad.go_id, "add_buff", { buff = "shield", amount = shield_val })
		end
	elseif ctype == cards.CARD_FIRE then
		target_squad.damage = math.floor(target_squad.damage * 1.3)
		target_squad.per_unit_damage = target_squad.damage / math.max(1, target_squad.unit_count)
		target_squad.has_fire = true
		if target_squad.go_id then
			msg.post(target_squad.go_id, "add_buff", { buff = "fire" })
		end
	elseif ctype == cards.CARD_RAGE then
		target_squad.attack_interval = target_squad.attack_interval * 0.7
		target_squad.speed = math.floor(target_squad.speed * 1.25)
		target_squad.has_rage = true
		if target_squad.go_id then
			msg.post(target_squad.go_id, "add_buff", { buff = "rage" })
		end
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
			-- Applied to squad!
			return M.apply_card(card_item, existing)
		else
			-- Target is another card or crate: swap them!
			local from_r, from_c = card_item.row, card_item.col
			grid.set_player_item(from_r, from_c, existing)
			grid.set_player_item(to_r, to_c, card_item)
			if card_item.go_id then
				msg.post(card_item.go_id, "snap", { pos = card_item.home_pos })
			end
			if existing.go_id then
				msg.post(existing.go_id, "snap", { pos = existing.home_pos })
			end
			M.save_game()
			return true
		end
	else
		-- Move to empty cell
		grid.set_player_item(card_item.row, card_item.col, nil)
		grid.set_player_item(to_r, to_c, card_item)
		if card_item.go_id then
			msg.post(card_item.go_id, "snap", { pos = card_item.home_pos })
		end
		M.save_game()
		return true
	end
end

function M.save_game()
	local squads_save = {}
	for _, sq in ipairs(player_squads) do
		table.insert(squads_save, {
			unit_type = sq.unit_type,
			tier = sq.tier,
			row = sq.row,
			col = sq.col,
		})
	end

	local cards_save = {}
	for _, c in ipairs(cards_on_field) do
		table.insert(cards_save, {
			card_type = c.card_type,
			row = c.row,
			col = c.col,
		})
	end

	local crates_save = {}
	for _, cr in ipairs(crates_on_field) do
		table.insert(crates_save, {
			row = cr.row,
			col = cr.col,
		})
	end

	local data = {
		level = current_level,
		coins = economy.get_coins(),
		buy_count = economy.get_buy_count(),
		tutorial_done = tutorial.is_completed(),
		rounds_since_crate = rounds_since_crate,
		player_squads = squads_save,
		cards = cards_save,
		crates = crates_save,
	}
	storage.save(data)
end

function M.load_game()
	local data = storage.load()
	if not data then return false end

	current_level = tonumber(data.level) or 1
	rounds_since_crate = tonumber(data.rounds_since_crate) or 0
	economy.set_state(data.coins, data.buy_count)
	if data.tutorial_done then
		tutorial.set_completed(true)
	end

	-- Clear player squads
	for i = 1, #player_squads do
		if view_handlers.despawn_squad then
			view_handlers.despawn_squad(player_squads[i])
		end
	end
	player_squads = {}

	-- Clear cards & crates
	for i = 1, #cards_on_field do
		if view_handlers.despawn_card then
			view_handlers.despawn_card(cards_on_field[i])
		end
	end
	cards_on_field = {}

	for i = 1, #crates_on_field do
		if view_handlers.despawn_crate then
			view_handlers.despawn_crate(crates_on_field[i])
		end
	end
	crates_on_field = {}

	grid.clear_player_cells()

	if data.player_squads and #data.player_squads > 0 then
		for _, s in ipairs(data.player_squads) do
			local squad = create_squad_data(config.TEAM_PLAYER, s.unit_type, s.tier, s.row, s.col)
			table.insert(player_squads, squad)
			grid.set_player_squad(s.row, s.col, squad)
			if view_handlers.spawn_squad then
				view_handlers.spawn_squad(squad)
			end
		end
	end

	if data.cards and #data.cards > 0 then
		for _, c in ipairs(data.cards) do
			M.spawn_card(c.card_type, c.row, c.col)
		end
	end

	if data.crates and #data.crates > 0 then
		for _, cr in ipairs(data.crates) do
			M.spawn_drop_crate(cr.row, cr.col)
		end
	end

	return true
end

function M.start_level(level_num)
	current_level = level_num or current_level
	set_phase(config.PHASE_PREP)

	-- Clear enemy squads
	for i = 1, #enemy_squads do
		if view_handlers.despawn_squad then
			view_handlers.despawn_squad(enemy_squads[i])
		end
	end
	enemy_squads = {}
	grid.clear_enemy_cells()

	-- Reset player squads positions to home cells, reset temporary battle buffs, and restore full HP
	for i = #player_squads, 1, -1 do
		local sq = player_squads[i]
		sq.has_shield = nil
		sq.shield_hp = nil
		sq.has_fire = nil
		sq.has_rage = nil
		refresh_squad_stats(sq)

		if sq.is_alive then
			sq.hp = sq.max_hp
			sq.alive_units = sq.unit_count
			sq.current_pos = vmath.vector3(sq.home_pos)
			sq.target = nil
			sq.attack_timer = 0
			if view_handlers.replenish_squad then
				view_handlers.replenish_squad(sq)
			elseif view_handlers.update_squad then
				view_handlers.update_squad(sq)
			end
		else
			-- If they died in previous failed battle, they revive at their home cell!
			sq.is_alive = true
			sq.hp = sq.max_hp
			sq.alive_units = sq.unit_count
			sq.current_pos = vmath.vector3(sq.home_pos)
			if view_handlers.spawn_squad then
				view_handlers.spawn_squad(sq)
			end
		end
	end

	-- Drop wooden loot crate every 3-4 rounds (levels)
	if current_level > 1 then
		rounds_since_crate = rounds_since_crate + 1
		if rounds_since_crate >= 3 then
			local empty_r, empty_c = grid.find_first_empty_player_cell()
			if empty_r and empty_c then
				rounds_since_crate = 0
				M.spawn_drop_crate(empty_r, empty_c)
			end
		end
	end

	-- Spawn enemies for level
	local level_data = levels.get_level(current_level)
	for _, e in ipairs(level_data.enemies) do
		local enemy_squad = create_squad_data(config.TEAM_ENEMY, e.unit_type, e.tier, e.row, e.col)
		table.insert(enemy_squads, enemy_squad)
		grid.set_enemy_squad(e.row, e.col, enemy_squad)
		if view_handlers.spawn_squad then
			view_handlers.spawn_squad(enemy_squad)
		end
	end

	-- If level 1 initial run and no player squads exist, spawn initial player squad
	if current_level == 1 and #player_squads == 0 and level_data.initial_player then
		for _, p in ipairs(level_data.initial_player) do
			local player_squad = create_squad_data(config.TEAM_PLAYER, p.unit_type, p.tier, p.row, p.col)
			table.insert(player_squads, player_squad)
			grid.set_player_squad(p.row, p.col, player_squad)
			if view_handlers.spawn_squad then
				view_handlers.spawn_squad(player_squad)
			end
		end
	end

	economy.reset_level_earned()
	tutorial.init_for_level(current_level)

	if view_handlers.level_changed then
		view_handlers.level_changed(current_level)
	end
	for i = 1, #level_callbacks do
		level_callbacks[i](current_level)
	end
	M.save_game()
end

function M.buy_unit()
	if phase ~= config.PHASE_PREP then return false end
	if not tutorial.is_buy_allowed() then return false end
	if not economy.can_afford_buy() then return false end

	local empty_r, empty_c
	if current_level == 1 and tutorial.get_step() == tutorial.STEP_BUY then
		-- In Level 1 tutorial, place right next to the initial squad (row 3, col 3)
		if grid.get_player_squad(3, 3) == nil then
			empty_r, empty_c = 3, 3
		else
			empty_r, empty_c = grid.find_first_empty_player_cell()
		end
	else
		empty_r, empty_c = grid.find_first_empty_player_cell()
	end

	if not empty_r then return false end -- Grid is full!

	if not economy.spend_for_buy() then return false end

	-- 5-7% rare chance to spawn an enhancer card instead of basic warrior!
	if current_level > 1 and math.random() < 0.07 then
		local card_type = cards.get_random_card_type()
		M.spawn_card(card_type, empty_r, empty_c)
		tutorial.advance_from_buy()
		M.save_game()
		return true
	end

	local unit_type, tier
	if current_level == 1 and tutorial.get_step() == tutorial.STEP_BUY then
		-- Spawn identical unit to match existing squad for merge tutorial
		unit_type = config.UNIT_MELEE
		tier = 1
	else
		unit_type = (math.random() > 0.5) and config.UNIT_MELEE or config.UNIT_ARCHER
		tier = (math.random() < 0.75) and 1 or 2
	end

	local squad = create_squad_data(config.TEAM_PLAYER, unit_type, tier, empty_r, empty_c)
	table.insert(player_squads, squad)
	grid.set_player_squad(empty_r, empty_c, squad)

	if view_handlers.spawn_squad then
		view_handlers.spawn_squad(squad)
	end

	tutorial.advance_from_buy()
	M.save_game()
	return true
end

function M.reward_buy_unit()
	if phase ~= config.PHASE_PREP then return false end

	local empty_r, empty_c = grid.find_first_empty_player_cell()
	if not empty_r then return false end -- Grid is full!

	local unit_type = (math.random() > 0.5) and config.UNIT_MELEE or config.UNIT_ARCHER
	local tier = (math.random() < 0.6) and 1 or 2

	local squad = create_squad_data(config.TEAM_PLAYER, unit_type, tier, empty_r, empty_c)
	table.insert(player_squads, squad)
	grid.set_player_squad(empty_r, empty_c, squad)

	if view_handlers.spawn_squad then
		view_handlers.spawn_squad(squad)
	end

	tutorial.advance_from_buy()
	M.save_game()
	return true
end


function M.merge_units(from_r, from_c, to_r, to_c)
	if phase ~= config.PHASE_PREP then return false end
	if from_r == to_r and from_c == to_c then return false end

	local squad_a = grid.get_player_squad(from_r, from_c)
	local squad_b = grid.get_player_squad(to_r, to_c)
	if not squad_a or not squad_b then return false end

	if squad_a.unit_type ~= squad_b.unit_type or squad_a.tier ~= squad_b.tier then
		-- Different unit type or tier: swap positions
		grid.set_player_squad(from_r, from_c, squad_b)
		grid.set_player_squad(to_r, to_c, squad_a)
		squad_a.current_pos = vmath.vector3(squad_a.home_pos)
		squad_b.current_pos = vmath.vector3(squad_b.home_pos)
		if view_handlers.snap_squad then
			view_handlers.snap_squad(squad_a)
			view_handlers.snap_squad(squad_b)
		elseif view_handlers.update_squad then
			view_handlers.update_squad(squad_a)
			view_handlers.update_squad(squad_b)
		end
		M.save_game()
		return false
	end

	-- Same type and tier: MERGE!
	local new_tier = math.min(config.MAX_TIER, squad_a.tier + 1)
	local unit_type = squad_a.unit_type

	-- Remove squad_a and squad_b from grid and list
	grid.set_player_squad(from_r, from_c, nil)
	grid.set_player_squad(to_r, to_c, nil)

	squad_a.is_alive = false
	squad_b.is_alive = false

	if view_handlers.despawn_squad then
		view_handlers.despawn_squad(squad_a)
		view_handlers.despawn_squad(squad_b)
	end

	for i = #player_squads, 1, -1 do
		if player_squads[i].id == squad_a.id or player_squads[i].id == squad_b.id then
			table.remove(player_squads, i)
		end
	end

	-- Create merged squad
	local new_squad = create_squad_data(config.TEAM_PLAYER, unit_type, new_tier, to_r, to_c)
	new_squad.is_merge = true
	table.insert(player_squads, new_squad)
	grid.set_player_squad(to_r, to_c, new_squad)

	if view_handlers.spawn_squad then
		view_handlers.spawn_squad(new_squad)
	end

	if view_handlers.play_effect then
		view_handlers.play_effect("merge", new_squad.home_pos, { tier = new_tier, unit_type = unit_type })
	end

	tutorial.advance_from_merge()
	M.save_game()
	return true
end

function M.move_squad(from_r, from_c, to_r, to_c)
	if phase ~= config.PHASE_PREP then return false end
	local squad = grid.get_player_squad(from_r, from_c)
	if not squad then return false end

	local existing = grid.get_player_item(to_r, to_c)
	if existing then
		if existing.is_card or existing.is_crate then
			-- Swap squad with card/crate on grid
			grid.set_player_item(from_r, from_c, existing)
			grid.set_player_item(to_r, to_c, squad)
			squad.current_pos = vmath.vector3(squad.home_pos)
			if view_handlers.snap_squad then
				view_handlers.snap_squad(squad)
			end
			if existing.go_id then
				msg.post(existing.go_id, "snap", { pos = existing.home_pos })
			end
			M.save_game()
			return true
		else
			return M.merge_units(from_r, from_c, to_r, to_c)
		end
	else
		grid.set_player_item(from_r, from_c, nil)
		grid.set_player_item(to_r, to_c, squad)
		squad.current_pos = vmath.vector3(squad.home_pos)
		if view_handlers.snap_squad then
			view_handlers.snap_squad(squad)
		elseif view_handlers.update_squad then
			view_handlers.update_squad(squad)
		end
		M.save_game()
		return true
	end
end

function M.start_battle()
	if phase ~= config.PHASE_PREP then return end
	if not tutorial.is_battle_allowed() then return end
	if #player_squads == 0 then return end

	poki.gameplay_start()
	tutorial.advance_from_battle()
	set_phase(config.PHASE_BATTLE)

	-- Reset combat timers and initialize positions
	for _, sq in ipairs(player_squads) do
		sq.current_pos = vmath.vector3(sq.home_pos)
		sq.target = nil
		sq.attack_timer = 0
		if sq.sub_units then
			for idx, u in ipairs(sq.sub_units) do
				u.attack_timer = (idx - 1) * 0.08 + math.random() * 0.1
			end
		end
	end
	for _, sq in ipairs(enemy_squads) do
		sq.current_pos = vmath.vector3(sq.home_pos)
		sq.target = nil
		sq.attack_timer = 0
		if sq.sub_units then
			for idx, u in ipairs(sq.sub_units) do
				u.attack_timer = (idx - 1) * 0.08 + math.random() * 0.1
			end
		end
	end
end

-- Find nearest living opponent squad using squared circle distance
local function find_nearest_target(squad, opponents)
	local best_target = nil
	local best_d2 = 999999999
	local sx, sy = squad.current_pos.x, squad.current_pos.y

	for i = 1, #opponents do
		local opp = opponents[i]
		if opp.is_alive then
			local dx = opp.current_pos.x - sx
			local dy = opp.current_pos.y - sy
			local d2 = dx * dx + dy * dy
			if d2 < best_d2 then
				best_d2 = d2
				best_target = opp
			end
		end
	end
	return best_target, math.sqrt(best_d2)
end

-- Apply separation force between friendly squads to prevent overlapping
local function apply_friendly_separation(squad, allies, dt)
	local sx, sy = squad.current_pos.x, squad.current_pos.y
	local r_repel = config.SQUAD_RADIUS * 2
	local r_repel_sq = r_repel * r_repel

	for i = 1, #allies do
		local ally = allies[i]
		if ally.id ~= squad.id and ally.is_alive then
			local dx = sx - ally.current_pos.x
			local dy = sy - ally.current_pos.y
			local d2 = dx * dx + dy * dy
			if d2 < r_repel_sq and d2 > 0.001 then
				local dist = math.sqrt(d2)
				local push = (r_repel - dist) / r_repel * config.REPEL_FORCE * dt
				squad.current_pos.x = squad.current_pos.x + (dx / dist) * push
				squad.current_pos.y = squad.current_pos.y + (dy / dist) * push
			end
		end
	end
end

function M.apply_damage(squad, amount)
	if not squad.is_alive then return end

	-- Shield absorption
	if squad.shield_hp and squad.shield_hp > 0 then
		local absorbed = math.min(squad.shield_hp, amount)
		squad.shield_hp = squad.shield_hp - absorbed
		amount = amount - absorbed
		if squad.shield_hp <= 0 then
			squad.has_shield = false
			if squad.go_id then
				msg.post(squad.go_id, "remove_buff", { buff = "shield" })
			end
		end
	end

	if amount <= 0 then
		if view_handlers.damage_squad then
			view_handlers.damage_squad(squad, 0)
		end
		return
	end

	local prev_alive = squad.alive_units or squad.unit_count

	squad.hp = math.max(0, squad.hp - amount)

	-- Update alive visual warriors based on remaining HP fraction
	local hp_frac = squad.hp / squad.max_hp
	local new_alive
	if squad.hp <= 0 then
		new_alive = 0
	else
		new_alive = math.max(1, math.ceil(hp_frac * squad.unit_count))
	end
	squad.alive_units = new_alive

	-- Award coins per killed unit for enemy squads
	if squad.team == config.TEAM_ENEMY and prev_alive > new_alive then
		local units_killed = prev_alive - new_alive
		local total_reward = config.KILL_REWARD * squad.tier
		-- Per-unit reward distributed across the squad's total units
		local per_unit_reward = total_reward / math.max(1, squad.unit_count)
		local reward = math.floor(units_killed * per_unit_reward + 0.5)
		if reward < 1 then
			reward = 1
		end
		economy.add_coins(reward, vmath.vector3(squad.current_pos))
	end

	if view_handlers.damage_squad then
		view_handlers.damage_squad(squad, amount)
	end

	if squad.hp <= 0 then
		squad.is_alive = false
		squad.alive_units = 0

		if view_handlers.despawn_squad then
			view_handlers.despawn_squad(squad)
		end
	end
end

function M.update_battle(dt)
	if phase ~= config.PHASE_BATTLE then return end

	local player_alive_count = 0
	local enemy_alive_count = 0

	for _, sq in ipairs(player_squads) do
		if sq.is_alive then player_alive_count = player_alive_count + 1 end
	end
	for _, sq in ipairs(enemy_squads) do
		if sq.is_alive then enemy_alive_count = enemy_alive_count + 1 end
	end

	-- Check Victory / Defeat conditions
	if enemy_alive_count == 0 then
		local level_data = levels.get_level(current_level)
		local win_reward = level_data.win_reward or config.WIN_REWARD
		economy.add_coins(win_reward, vmath.vector3(150, 400, 0))
		poki.gameplay_stop()
		M.start_level(current_level + 1)
		return
	elseif player_alive_count == 0 then
		poki.gameplay_stop()
		M.start_level(current_level)
		return
	end

	-- Process all living squads: player squads move/attack enemy, and vice versa
	local all_groups = {
		{ list = player_squads, foes = enemy_squads },
		{ list = enemy_squads, foes = player_squads }
	}

	for _, g in ipairs(all_groups) do
		for _, squad in ipairs(g.list) do
			if squad.is_alive then
				-- Validate or find target
				if not squad.target or not squad.target.is_alive then
					squad.target = find_nearest_target(squad, g.foes)
				end

				if squad.target and squad.target.is_alive then
					local tx = squad.target.current_pos.x
					local ty = squad.target.current_pos.y
					local dx = tx - squad.current_pos.x
					local dy = ty - squad.current_pos.y
					local dist = math.sqrt(dx * dx + dy * dy)

					if dist > squad.attack_range then
						-- Move towards target
						local move_dist = squad.speed * dt
						squad.current_pos.x = squad.current_pos.x + (dx / dist) * move_dist
						squad.current_pos.y = squad.current_pos.y + (dy / dist) * move_dist
					else
						-- Within attack range: EACH living unit in the squad attacks independently!
						local active_units = math.min(squad.alive_units or 1, squad.unit_count or 1)
						local unit_dmg = squad.per_unit_damage or (squad.damage / active_units)

						if squad.sub_units then
							for u_idx = 1, active_units do
								local u = squad.sub_units[u_idx]
								if u then
									u.attack_timer = u.attack_timer - dt
									if u.attack_timer <= 0 then
										u.attack_timer = squad.attack_interval + (math.random() - 0.5) * 0.12

										if squad.unit_type == config.UNIT_ARCHER then
											-- Each archer fires their own arrow from their individual formation position!
											local origin = vmath.vector3(squad.current_pos.x + u.offset.x, squad.current_pos.y + u.offset.y, squad.current_pos.z)
											if view_handlers.shoot_projectile then
												view_handlers.shoot_projectile(squad, squad.target, unit_dmg, squad.miss_radius, origin)
											end
										elseif squad.unit_type == config.UNIT_MELEE then
											-- Each melee fighter pounds the enemy independently
											M.apply_damage(squad.target, unit_dmg)
											if view_handlers.attack_squad then
												view_handlers.attack_squad(squad, squad.target)
											end
										end
									end
								end
							end
						end
					end
				end

				-- Circle separation between friendly squads
				apply_friendly_separation(squad, g.list, dt)

				-- Clamp inside arena bounds
				squad.current_pos.x = math.max(60, math.min(340, squad.current_pos.x))
				squad.current_pos.y = math.max(60, math.min(540, squad.current_pos.y))

				if view_handlers.update_squad then
					view_handlers.update_squad(squad)
				end
			end
		end
	end
end

return M
