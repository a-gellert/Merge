-- Pure-Lua sound interface with voice throttling and pitch variation
local M = {}

local muted = false
local last_play_time = {}
local frame_play_count = {}
local last_frame_reset = 0

-- Maximum plays of a specific sound effect within a single frame
local MAX_PER_FRAME = {
	slash = 3,
	hit = 3,
	coin = 2,
	shoot = 3,
	merge = 2,
	click = 2,
}

local function get_time()
	if socket and socket.gettime then return socket.gettime() end
	return os.clock()
end

function M.is_muted()
	return muted
end

function M.set_muted(val)
	muted = val
	pcall(function()
		sound.set_group_gain("master", muted and 0 or 1)
	end)
end

function M.toggle_muted()
	M.set_muted(not muted)
	return muted
end

function M.on_ad_start()
	pcall(function()
		sound.set_group_gain("master", 0)
	end)
end

function M.on_ad_stop()
	if not muted then
		pcall(function()
			sound.set_group_gain("master", 1)
		end)
	end
end

function M.play(sound_name, gain, speed)
	if muted or not sound_name then return end

	local now = get_time()
	if now - last_frame_reset > 0.04 then
		frame_play_count = {}
		last_frame_reset = now
	end

	local max_count = MAX_PER_FRAME[sound_name] or 4
	local current_count = frame_play_count[sound_name] or 0
	if current_count >= max_count then return end
	frame_play_count[sound_name] = current_count + 1

	local target_speed = (speed or 1.0) * (0.96 + math.random() * 0.08)
	local target_gain = gain or 1.0

	local url = "/sound_manager#sound_" .. sound_name
	pcall(function()
		sound.play(url, { gain = target_gain, speed = target_speed })
	end)
end

return M
