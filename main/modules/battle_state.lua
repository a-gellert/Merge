local config = require("main.modules.config")
local levels = require("main.modules.levels")
local economy = require("main.modules.economy")
local grid = require("main.modules.grid")
local tutorial = require("main.modules.tutorial")
local poki = require("main.modules.poki")

local M = {}

local current_level = 1
local phase = config.PHASE_PREP

local player_squads = {}
local enemy_squads = {}
local next_squad_id = 1

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
		attack_interval = stats.attack_interval,
		attack_range = stats.attack_range,
		speed = stats.speed,
		miss_radius = stats.miss_radius,
		unit_count = stats.unit_count,
		alive_units = stats.unit_count,
		attack_timer = math.random() * 0.3,
		target = nil,
		is_alive = true,
		go_id = nil,
	}
	return squad
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

	-- Reset player squads positions to home cells and restore full HP
	for i = #player_squads, 1, -1 do
		local sq = player_squads[i]
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

	tutorial.advance_from_merge()
	return true
end

function M.move_squad(from_r, from_c, to_r, to_c)
	if phase ~= config.PHASE_PREP then return false end
	local squad = grid.get_player_squad(from_r, from_c)
	if not squad then return false end

	local existing = grid.get_player_squad(to_r, to_c)
	if existing then
		return M.merge_units(from_r, from_c, to_r, to_c)
	else
		grid.set_player_squad(from_r, from_c, nil)
		grid.set_player_squad(to_r, to_c, squad)
		squad.current_pos = vmath.vector3(squad.home_pos)
		if view_handlers.snap_squad then
			view_handlers.snap_squad(squad)
		elseif view_handlers.update_squad then
			view_handlers.update_squad(squad)
		end
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
	end
	for _, sq in ipairs(enemy_squads) do
		sq.current_pos = vmath.vector3(sq.home_pos)
		sq.target = nil
		sq.attack_timer = 0
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
	squad.hp = math.max(0, squad.hp - amount)

	-- Update alive visual warriors based on remaining HP fraction
	local hp_frac = squad.hp / squad.max_hp
	squad.alive_units = math.max(1, math.ceil(hp_frac * squad.unit_count))

	if view_handlers.damage_squad then
		view_handlers.damage_squad(squad, amount)
	end

	if squad.hp <= 0 then
		squad.is_alive = false
		squad.alive_units = 0

		if squad.team == config.TEAM_ENEMY then
			local reward = config.KILL_REWARD * squad.tier
			economy.add_coins(reward)
		end

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
		economy.add_coins(win_reward)
		poki.gameplay_stop()
		set_phase(config.PHASE_VICTORY)
		return
	elseif player_alive_count == 0 then
		poki.gameplay_stop()
		set_phase(config.PHASE_DEFEAT)
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
						-- Within attack range!
						squad.attack_timer = squad.attack_timer - dt
						if squad.attack_timer <= 0 then
							squad.attack_timer = squad.attack_interval

							if squad.unit_type == config.UNIT_MELEE then
								-- Direct melee strike
								M.apply_damage(squad.target, squad.damage)
								if view_handlers.attack_squad then
									view_handlers.attack_squad(squad, squad.target)
								end
							elseif squad.unit_type == config.UNIT_ARCHER then
								-- Archer projectile shoot
								if view_handlers.shoot_projectile then
									view_handlers.shoot_projectile(squad, squad.target, squad.damage, squad.miss_radius)
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
