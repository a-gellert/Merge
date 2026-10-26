-- Pure-Lua arrow simulation (arcing flight). Rendering lives in projectile_manager.script,
-- which mirrors this pool onto pre-created sprites.
local config = require("main.modules.config")

local M = {}

local pool = {}
local spawn_counter = 0

function M.init(size)
	pool = {}
	for i = 1, size or config.PROJECTILE_POOL_SIZE do
		pool[i] = { active = false, version = 0, x = 0, y = -2000, angle = 0 }
	end
end

function M.get_pool()
	return pool
end

function M.clear()
	for i = 1, #pool do
		pool[i].active = false
	end
end

function M.spawn(from_x, from_y, target, damage, miss_radius, is_fire, team)
	local arrow
	for i = 1, #pool do
		if not pool[i].active then
			arrow = pool[i]
			break
		end
	end
	if not arrow then return false end

	-- Aim at a random living warrior of the target formation, with a little scatter
	local ox, oy = 0, 0
	local alive = math.min(target.alive_units or 1, target.sub_units and #target.sub_units or 1)
	if target.sub_units and alive > 0 then
		local u = target.sub_units[math.random(1, alive)]
		if u and u.offset then
			ox, oy = u.offset.x, u.offset.y
		end
	end
	if miss_radius and miss_radius > 0 then
		local a = math.random() * math.pi * 2
		local rr = math.random() * miss_radius * 0.4
		ox = ox + math.cos(a) * rr
		oy = oy + math.sin(a) * rr
	end

	local tx = target.current_pos.x + ox
	local ty = target.current_pos.y + oy
	local dx, dy = tx - from_x, ty - from_y
	local dist = math.max(1, math.sqrt(dx * dx + dy * dy))

	spawn_counter = spawn_counter + 1
	arrow.active = true
	arrow.version = spawn_counter
	arrow.sx, arrow.sy = from_x, from_y
	arrow.tx, arrow.ty = tx, ty
	arrow.x, arrow.y = from_x, from_y
	arrow.t = 0
	arrow.dur = dist / config.PROJECTILE_SPEED
	arrow.h = math.min(42, dist * 0.28)
	arrow.target = target
	arrow.damage = damage
	arrow.is_fire = is_fire
	arrow.team = team
	arrow.angle = math.atan2(dy, dx)
	return true
end

-- on_hit(target, damage, x, y, is_fire) is called when an arrow lands on its squad
function M.update(dt, on_hit)
	for i = 1, #pool do
		local p = pool[i]
		if p.active then
			p.t = p.t + dt / p.dur
			if p.t >= 1 then
				p.active = false
				local tgt = p.target
				p.target = nil
				if tgt and tgt.is_alive then
					local hx = p.tx - tgt.current_pos.x
					local hy = p.ty - tgt.current_pos.y
					local hit_r = math.max(config.PROJECTILE_HIT_RADIUS, 4.0 * math.sqrt(tgt.unit_count or 1) + 16)
					if hx * hx + hy * hy <= hit_r * hit_r then
						on_hit(tgt, p.damage, p.tx, p.ty, p.is_fire)
					end
				end
			else
				local t = p.t
				local lift = p.h * 4 * t * (1 - t)
				p.x = p.sx + (p.tx - p.sx) * t
				p.y = p.sy + (p.ty - p.sy) * t + lift
				local vx = (p.tx - p.sx)
				local vy = (p.ty - p.sy) + p.h * 4 * (1 - 2 * t)
				p.angle = math.atan2(vy, vx)
				p.lift = lift
			end
		end
	end
end

return M
