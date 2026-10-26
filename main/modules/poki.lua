-- Poki SDK wrapper: gameplay events, interstitials (commercial breaks),
-- rewarded ads with cooldowns, and analytics. Works as a no-op outside Poki.
local M = {}

local is_gameplay_active = false
local is_ad_active = false
local levels_since_break = 0
local last_rewarded_time = -1000
local clock = 0

-- Interstitials: never before this level, and at most every N finished levels.
-- Poki additionally throttles commercial breaks on its side.
M.FIRST_BREAK_LEVEL = 4
M.LEVELS_PER_BREAK = 2

local function sdk()
	return rawget(_G, "poki_sdk")
end

function M.update(dt)
	clock = clock + dt
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

-- Natural break between levels. Skipped early and right after a rewarded ad.
function M.level_break(level, on_complete)
	levels_since_break = levels_since_break + 1
	local recently_rewarded = (clock - last_rewarded_time) < 60
	if level < M.FIRST_BREAK_LEVEL or levels_since_break < M.LEVELS_PER_BREAK or recently_rewarded then
		if on_complete then on_complete() end
		return
	end
	levels_since_break = 0
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
		last_rewarded_time = clock
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
			local ok = (status == s.REWARDED_BREAK_SUCCESS)
			if ok then last_rewarded_time = clock end
			if on_reward then on_reward(ok) end
		end
	end)
end

return M
