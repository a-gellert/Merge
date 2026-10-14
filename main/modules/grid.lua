local config = require("main.modules.config")

local M = {}

-- Player grid occupancy: [row][col] = squad_or_nil
local player_cells = {}
-- Enemy grid occupancy: [row][col] = squad_or_nil
local enemy_cells = {}

function M.init()
	player_cells = {}
	enemy_cells = {}
	for r = 1, config.GRID_ROWS do
		player_cells[r] = {}
		enemy_cells[r] = {}
		for c = 1, config.GRID_COLS do
			player_cells[r][c] = nil
			enemy_cells[r][c] = nil
		end
	end
end

function M.get_cell_pos(team, row, col)
	local x = config.COL_X[col] or 200
	local y
	if team == config.TEAM_PLAYER then
		y = config.PLAYER_ROW_Y[row] or 200
	else
		y = config.ENEMY_ROW_Y[row] or 400
	end
	return vmath.vector3(x, y, 0)
end

-- Find player cell from world coordinates (x, y)
function M.world_to_player_cell(wx, wy)
	local half_cell = config.CELL_SIZE * 0.5 + 4
	for r = 1, config.GRID_ROWS do
		local cy = config.PLAYER_ROW_Y[r]
		if math.abs(wy - cy) <= half_cell then
			for c = 1, config.GRID_COLS do
				local cx = config.COL_X[c]
				if math.abs(wx - cx) <= half_cell then
					return r, c
				end
			end
		end
	end
	return nil, nil
end

function M.get_player_item(row, col)
	if player_cells[row] then
		return player_cells[row][col]
	end
	return nil
end

function M.set_player_item(row, col, item)
	if player_cells[row] then
		player_cells[row][col] = item
		if item then
			item.row = row
			item.col = col
			item.home_pos = M.get_cell_pos(config.TEAM_PLAYER, row, col)
		end
	end
end

function M.get_player_squad(row, col)
	if player_cells[row] then
		local it = player_cells[row][col]
		if it and not it.is_card and not it.is_crate then
			return it
		end
	end
	return nil
end

function M.set_player_squad(row, col, squad)
	M.set_player_item(row, col, squad)
end

function M.get_player_card(row, col)
	if player_cells[row] then
		local it = player_cells[row][col]
		if it and it.is_card then
			return it
		end
	end
	return nil
end

function M.get_player_crate(row, col)
	if player_cells[row] then
		local it = player_cells[row][col]
		if it and it.is_crate then
			return it
		end
	end
	return nil
end

function M.get_enemy_squad(row, col)
	if enemy_cells[row] then
		return enemy_cells[row][col]
	end
	return nil
end

function M.set_enemy_squad(row, col, squad)
	if enemy_cells[row] then
		enemy_cells[row][col] = squad
		if squad then
			squad.row = row
			squad.col = col
			squad.home_pos = M.get_cell_pos(config.TEAM_ENEMY, row, col)
		end
	end
end

-- Find first empty cell on player grid (searching row 1 to 4, col 1 to 4)
function M.find_first_empty_player_cell()
	for r = 1, config.GRID_ROWS do
		for c = 1, config.GRID_COLS do
			if player_cells[r][c] == nil then
				return r, c
			end
		end
	end
	return nil, nil
end

function M.clear_player_cells()
	for r = 1, config.GRID_ROWS do
		for c = 1, config.GRID_COLS do
			player_cells[r][c] = nil
		end
	end
end

function M.clear_enemy_cells()
	for r = 1, config.GRID_ROWS do
		for c = 1, config.GRID_COLS do
			enemy_cells[r][c] = nil
		end
	end
end

function M.get_all_player_squads()
	local list = {}
	for r = 1, config.GRID_ROWS do
		for c = 1, config.GRID_COLS do
			local it = player_cells[r][c]
			if it ~= nil and not it.is_card and not it.is_crate then
				table.insert(list, it)
			end
		end
	end
	return list
end

function M.get_all_player_cards()
	local list = {}
	for r = 1, config.GRID_ROWS do
		for c = 1, config.GRID_COLS do
			local it = player_cells[r][c]
			if it ~= nil and it.is_card then
				table.insert(list, it)
			end
		end
	end
	return list
end

function M.get_all_player_crates()
	local list = {}
	for r = 1, config.GRID_ROWS do
		for c = 1, config.GRID_COLS do
			local it = player_cells[r][c]
			if it ~= nil and it.is_crate then
				table.insert(list, it)
			end
		end
	end
	return list
end

function M.get_all_enemy_squads()
	local list = {}
	for r = 1, config.GRID_ROWS do
		for c = 1, config.GRID_COLS do
			if enemy_cells[r][c] ~= nil then
				table.insert(list, enemy_cells[r][c])
			end
		end
	end
	return list
end

M.init()

return M
