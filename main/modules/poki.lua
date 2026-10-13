local M = {}

local is_gameplay_active = false
local is_commercial_active = false

-- Called on player input (first click/touch or user action)
function M.on_player_input()
	if not is_gameplay_active and not is_commercial_active then
		is_gameplay_active = true
		if poki_sdk and poki_sdk.gameplay_start then
			poki_sdk.gameplay_start()
		end
	end
end

function M.gameplay_start()
	if not is_gameplay_active and not is_commercial_active then
		is_gameplay_active = true
		if poki_sdk and poki_sdk.gameplay_start then
			poki_sdk.gameplay_start()
		end
	end
end

function M.gameplay_stop()
	if is_gameplay_active then
		is_gameplay_active = false
		if poki_sdk and poki_sdk.gameplay_stop then
			poki_sdk.gameplay_stop()
		end
	end
end

-- Poki commercial break between levels / on retry
function M.commercial_break(on_complete)
	if poki_sdk and poki_sdk.commercial_break then
		M.gameplay_stop()
		is_commercial_active = true
		poki_sdk.commercial_break(function(_, status)
			if status == poki_sdk.COMMERCIAL_BREAK_START then
				is_commercial_active = true
			elseif status == poki_sdk.COMMERCIAL_BREAK_SUCCESS or status == nil then
				is_commercial_active = false
				if on_complete then
					on_complete()
				end
			end
		end)
	else
		if on_complete then
			on_complete()
		end
	end
end

-- Poki rewarded video break for bonus coins/boosts
function M.rewarded_break(size, on_reward)
	if poki_sdk and poki_sdk.rewarded_break then
		M.gameplay_stop()
		is_commercial_active = true
		poki_sdk.rewarded_break(size or "small", function(_, status)
			if status == poki_sdk.REWARDED_BREAK_START then
				is_commercial_active = true
			elseif status == poki_sdk.REWARDED_BREAK_SUCCESS then
				is_commercial_active = false
				if on_reward then on_reward(true) end
			elseif status == poki_sdk.REWARDED_BREAK_ERROR then
				is_commercial_active = false
				if on_reward then on_reward(false) end
			end
		end)
	else
		if on_reward then on_reward(true) end
	end
end

return M
