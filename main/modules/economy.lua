local config = require("main.modules.config")

local M = {}

local coins = config.START_COINS
local displayed_coins = config.START_COINS
local buy_count = 0
local level_earned = 0
local on_change_callbacks = {}
local on_earn_callbacks = {}

function M.get_coins()
	return coins
end

function M.get_displayed_coins()
	return math.floor(displayed_coins)
end

function M.get_buy_cost()
	local cost = config.BASE_BUY_COST -- 10
	if buy_count <= 20 then
		cost = cost + buy_count * 4
	elseif buy_count <= 45 then
		cost = cost + 20 * 4 + (buy_count - 20) * 8
	elseif buy_count <= 80 then
		cost = cost + 20 * 4 + 25 * 8 + (buy_count - 45) * 14
	else
		-- Мягкое плато с потолком 1200 монет, чтобы игрок всегда мог докупать юнитов
		cost =  cost + 20 * 4 + 25 * 8 + 35 * 14 + (buy_count - 80) * 18
	end
	return cost
end

local function notify()
	local disp = math.floor(displayed_coins)
	for i = 1, #on_change_callbacks do
		on_change_callbacks[i](disp, M.get_buy_cost())
	end
end

function M.get_buy_count()
	return buy_count
end

function M.set_state(saved_coins, saved_buy_count)
	coins = tonumber(saved_coins) or config.START_COINS
	displayed_coins = coins
	buy_count = tonumber(saved_buy_count) or 0
	notify()
end

function M.can_afford_buy()
	return coins >= M.get_buy_cost()
end

function M.get_level_earned()
	return level_earned
end

function M.reset_level_earned()
	level_earned = 0
end

function M.on_change(cb)
	table.insert(on_change_callbacks, cb)
end

function M.on_earn(cb)
	table.insert(on_earn_callbacks, cb)
end

function M.clear_callbacks()
	on_change_callbacks = {}
	on_earn_callbacks = {}
end

function M.add_coins(amount, origin_pos)
	if amount <= 0 then return end
	coins = coins + amount
	level_earned = level_earned + amount
	notify()
	for i = 1, #on_earn_callbacks do
		on_earn_callbacks[i](amount, origin_pos)
	end
end

function M.update(dt)
	if coins == displayed_coins then return end

	local diff = coins - displayed_coins
	if math.abs(diff) <= 0.05 then
		displayed_coins = coins
		notify()
		return
	end

	-- Gradually increase/transfer coins over roughly 0.6 - 1.0 second or minimum speed
	local speed = math.max(10, math.abs(diff) * 4.0)
	local step = speed * dt
	if step >= math.abs(diff) then
		displayed_coins = coins
	else
		displayed_coins = displayed_coins + (diff > 0 and step or -step)
	end
	notify()
end

function M.spend_for_buy()
	local cost = M.get_buy_cost()
	if coins < cost then
		return false
	end
	coins = coins - cost
	displayed_coins = coins
	buy_count = buy_count + 1
	notify()
	return true
end

function M.reset()
	coins = config.START_COINS
	displayed_coins = coins
	buy_count = 0
	level_earned = 0
	notify()
end

return M
