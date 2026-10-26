-- Poki SDK wrapper: gameplay events, interstitials (commercial breaks),
-- rewarded ads with cooldowns, and analytics. Works as a no-op outside Poki.
local M = {}

local is_gameplay_active = false
local is_ad_active = false
local rounds_since_break = 0

-- Interstitial once every N finished rounds (wins and losses count the same).
-- Poki additionally throttles commercial breaks on its side.
M.ROUNDS_PER_BREAK = 5

local function sdk()
	return rawget(_G, "poki_sdk")
end

function M.is_ad_active()
	return is_ad_active
end

function M.on_player_input()
	M.gameplay_start()
end

function M.gameplay_start()
	if not is_gameplay_active and not is_ad_active then
		is_gameplay_active = true
		local s = sdk()
		if s and s.gameplay_start then s.gameplay_start() end
	end
end

function M.gameplay_stop()
	if is_gameplay_active then
		is_gameplay_active = false
		local s = sdk()
		if s and s.gameplay_stop then s.gameplay_stop() end
	end
end

function M.measure(category, what, action)
	local s = sdk()
	if s and s.measure then
		pcall(s.measure, category, what, action)
	end
end

-- Natural break after every finished round; a commercial every ROUNDS_PER_BREAK rounds
function M.level_break(on_complete)
	rounds_since_break = rounds_since_break + 1
	if rounds_since_break < M.ROUNDS_PER_BREAK then
		if on_complete then on_complete() end
		return
	end
	rounds_since_break = 0
	M.commercial_break(on_complete)
end

function M.commercial_break(on_complete)
	local s = sdk()
	if not (s and s.commercial_break) then
		if on_complete then on_complete() end
		return
	end
	M.gameplay_stop()
	is_ad_active = true
	local done = false
	s.commercial_break(function(_, status)
		if status == s.COMMERCIAL_BREAK_START then
			is_ad_active = true
		elseif not done then
			done = true
			is_ad_active = false
			if on_complete then on_complete() end
		end
	end)
end

-- Rewarded break. on_reward(success)
function M.rewarded_break(size, on_reward)
	local s = sdk()
	if not (s and s.rewarded_break) then
		if on_reward then on_reward(true) end
		return
	end
	M.gameplay_stop()
	is_ad_active = true
	local done = false
	s.rewarded_break(size or "small", function(_, status)
		if status == s.REWARDED_BREAK_START then
			is_ad_active = true
		elseif not done then
			done = true
			is_ad_active = false
			if on_reward then on_reward(status == s.REWARDED_BREAK_SUCCESS) end
		end
	end)
end

return M
