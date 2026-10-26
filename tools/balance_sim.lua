-- Headless balance simulation: a bot plays the campaign through the real modules.
-- usage: luajit tools/balance_sim.lua . [levels=200] [v|x] [skill=1.0] [seed=42]
-- luajit ships with Defold: %LOCALAPPDATA%/Defold/unpack/<sha>/x86_64-win32/bin/luajit-64.exe
local root = arg[1]
local MAX_LEVEL = tonumber(arg[2]) or 200
local VERBOSE = arg[3] == "v"
local SKILL = tonumber(arg[4]) or 1.0 -- 1 = smart bot, <1 = sloppier (skips some merges/buys)
package.path = root .. "/?.lua;" .. package.path

-- ---- Defold stubs ----
local V3 = {}
V3.__index = V3
local function v3(x, y, z)
	if type(x) == "table" then return setmetatable({ x = x.x, y = x.y, z = x.z or 0 }, V3) end
	return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, V3)
end
V3.__add = function(a, b) return v3(a.x + b.x, a.y + b.y, a.z + b.z) end
V3.__sub = function(a, b) return v3(a.x - b.x, a.y - b.y, a.z - b.z) end
V3.__mul = function(a, b)
	if type(a) == "number" then a, b = b, a end
	return v3(a.x * b, a.y * b, a.z * b)
end
vmath = {
	vector3 = v3,
	vector4 = function(x, y, z, w) return { x = x or 0, y = y or 0, z = z or 0, w = w or 0 } end,
}
hash = function(s) return s end
msg = { post = function() end }
go = { exists = function() return false end }
timer = { delay = function(_, _, cb) cb() end }
sys = {
	get_save_file = function() return "x" end,
	save = function() return true end,
	load = function() return {} end,
	get_sys_info = function() return { language = "en" } end,
}
math.randomseed(tonumber(arg[5]) or 42)

local config = require("main.modules.config")
local levels = require("main.modules.levels")
local economy = require("main.modules.economy")
local bs = require("main.modules.battle_state")
local cards = require("main.modules.cards")
local tutorial = require("main.modules.tutorial")

local function fmt(n)
	if n >= 1e9 then return string.format("%.1fB", n / 1e9) end
	if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
	if n >= 1e3 then return string.format("%.1fK", n / 1e3) end
	return string.format("%d", n)
end

local function best_squad(pred)
	local best
	for _, sq in ipairs(bs.get_player_squads()) do
		if pred(sq) and (not best or sq.tier > best.tier) then best = sq end
	end
	return best
end

local function bot_prep()
	local actions = 0
	-- crates & cards
	for _, cr in ipairs({ unpack(bs.get_crates()) }) do
		bs.open_crate(cr); actions = actions + 1
	end
	for _, c in ipairs({ unpack(bs.get_cards()) }) do
		local t = c.card_type
		local target
		if t == cards.CARD_UPGRADE or t == cards.CARD_CLONE then
			target = best_squad(function(s) return cards.can_apply(t, s) end)
		elseif t == cards.CARD_SHIELD or t == cards.CARD_RAGE then
			target = best_squad(function(s) return s.unit_type == config.UNIT_MELEE end)
		elseif t == cards.CARD_FIRE then
			target = best_squad(function(s) return s.unit_type == config.UNIT_ARCHER end)
		end
		if target and cards.can_apply(t, target) then
			bs.apply_card(c, target)
		else
			bs.sell_card(c)
		end
		actions = actions + 1
	end

	for _ = 1, 60 do
		if math.random() > SKILL then break end
		local merged = false
		while bs.can_auto_merge() do
			local a, b = bs.find_merge_pair()
			bs.merge_units(a.row, a.col, b.row, b.col)
			actions = actions + 1
			merged = true
		end
		if economy.can_afford_buy() then
			local melee, archer = 0, 0
			for _, sq in ipairs(bs.get_player_squads()) do
				if sq.unit_type == config.UNIT_MELEE then melee = melee + 1 else archer = archer + 1 end
			end
			local t = (archer < melee * 0.6) and config.UNIT_ARCHER or config.UNIT_MELEE
			if bs.has_free_cell() then
				bs.buy_unit(t)
				actions = actions + 1
			else
				-- full grid, nothing to merge: sell the weakest if it is below shop tier
				local weakest
				for _, sq in ipairs(bs.get_player_squads()) do
					if not weakest or sq.tier < weakest.tier then weakest = sq end
				end
				if weakest and weakest.tier <= economy.get_shop_tier() then
					bs.sell_squad(weakest)
					actions = actions + 1
				else
					break
				end
			end
		elseif not merged then
			break
		end
	end
	return actions
end

local total_time = 0
local human_time = 0
local ch = {w=0,l=0,ratio=0,bt=0,n=0}
local losses_total = 0
local level_losses = 0
local level = 1
local milestones = { 150, 300, 600, 900, 1800, 3600, 7200, 10800, 14400 }
local mi = 1

bs.start_level(1)
local rows = {}
local battles, btime_sum = 0, 0

while level <= MAX_LEVEL do
	local actions = bot_prep()
	local p_pow, e_pow = bs.get_player_power(), bs.get_enemy_power()
	bs.start_battle()
	local t = 0
	while bs.get_phase() == config.PHASE_BATTLE and t < 150 do
		bs.update_battle(1 / 30)
		t = t + 1 / 30
	end
	local res = bs.get_last_result()
	local prep_time = 4 + actions * 1.3
	local level_time = prep_time + t + 3.5
	total_time = total_time + level_time
	human_time = human_time + 8 + actions * 2.2 + t + 5
	ch.n = ch.n + 1; ch.bt = ch.bt + t; ch.ratio = ch.ratio + p_pow / e_pow
	if res.win then ch.w = ch.w + 1 else ch.l = ch.l + 1 end
	battles = battles + 1
	btime_sum = btime_sum + t

	if VERBOSE then
		print(string.format("L%3d s%2d %s  P %7s vs E %7s  battle %5.1fs prep %4.1fs  best T%2d shop T%2d coins %7s  t=%5.1fm",
			level, levels.get_step(level), res.win and "WIN " or "LOSE", fmt(p_pow), fmt(e_pow), t, prep_time,
			economy.get_best_tier(), economy.get_shop_tier(), fmt(economy.get_coins()), total_time / 60))
	end

	if res.win and levels.get_step(level) == 10 and not VERBOSE then
		print(string.format("ch%2d L%3d  W%2d L%2d  P/E %.2f  battle %4.1fs  best T%2d  bot %5.1fm  human %5.1fm", levels.get_chapter(level), level, ch.w, ch.l, ch.ratio / ch.n, ch.bt / ch.n, economy.get_best_tier(), total_time / 60, human_time / 60))
		ch = {w=0,l=0,ratio=0,bt=0,n=0}
	end
	while mi <= #milestones and human_time >= milestones[mi] do
		rows[#rows + 1] = string.format("%5.1f min -> level %3d, best T%d", milestones[mi] / 60, level, economy.get_best_tier())
		mi = mi + 1
	end

	-- battle_state advances on its own (next level on win, restart on loss)
	if res.win then
		level = level + 1
		level_losses = 0
	else
		losses_total = losses_total + 1
		level_losses = level_losses + 1
		if level_losses >= 8 then
			print("HARD WALL at level " .. level)
			break
		end
	end
end

print(string.format("levels %d, total %.1f min, losses %d, avg battle %.1fs, best T%d",
	level - 1, total_time / 60, losses_total, btime_sum / battles, economy.get_best_tier()))
for _, r in ipairs(rows) do print(r) end
