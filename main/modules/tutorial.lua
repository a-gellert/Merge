local M = {}

M.STEP_NONE = 0
M.STEP_BUY = 1
M.STEP_MERGE = 2
M.STEP_BATTLE = 3
M.STEP_DONE = 4

local current_step = M.STEP_BUY
local is_completed = false
local step_callbacks = {}

function M.init_for_level(level_num)
	if level_num == 1 and not is_completed then
		current_step = M.STEP_BUY
	else
		current_step = M.STEP_NONE
	end
	M.notify()
end

function M.get_step()
	return current_step
end

function M.is_active()
	return current_step ~= M.STEP_NONE and current_step ~= M.STEP_DONE
end

function M.is_buy_allowed()
	if current_step == M.STEP_NONE or current_step == M.STEP_DONE then
		return true
	end
	return current_step == M.STEP_BUY
end

function M.is_merge_allowed()
	if current_step == M.STEP_NONE or current_step == M.STEP_DONE then
		return true
	end
	return current_step == M.STEP_MERGE
end

function M.is_battle_allowed()
	if current_step == M.STEP_NONE or current_step == M.STEP_DONE then
		return true
	end
	return current_step == M.STEP_BATTLE
end

function M.advance_from_buy()
	if current_step == M.STEP_BUY then
		current_step = M.STEP_MERGE
		M.notify()
	end
end

function M.advance_from_merge()
	if current_step == M.STEP_MERGE then
		current_step = M.STEP_BATTLE
		M.notify()
	end
end

function M.advance_from_battle()
	if current_step == M.STEP_BATTLE then
		current_step = M.STEP_DONE
		is_completed = true
		M.notify()
	end
end

function M.on_change(cb)
	table.insert(step_callbacks, cb)
end

function M.clear_callbacks()
	step_callbacks = {}
end

function M.notify()
	for i = 1, #step_callbacks do
		step_callbacks[i](current_step)
	end
end

return M
