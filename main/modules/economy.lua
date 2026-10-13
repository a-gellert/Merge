local config = require("main.modules.config")

local M = {}

local coins = config.START_COINS
local buy_count = 0
local level_earned = 0
local on_change_callbacks = {}

function M.get_coins()
	return coins
end

function M.get_buy_cost()
	return config.BASE_BUY_COST + buy_count * config.BUY_COST_STEP
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

local function notify()
	for i = 1, #on_change_callbacks do
		on_change_callbacks[i](coins, M.get_buy_cost())
	end
end

function M.on_change(cb)
	table.insert(on_change_callbacks, cb)
end

function M.clear_callbacks()
	on_change_callbacks = {}
end

function M.add_coins(amount)
	if amount <= 0 then return end
	coins = coins + amount
	level_earned = level_earned + amount
	notify()
end

function M.spend_for_buy()
	local cost = M.get_buy_cost()
	if coins < cost then
		return false
	end
	coins = coins - cost
	buy_count = buy_count + 1
	notify()
	return true
end

function M.reset()
	coins = config.START_COINS
	buy_count = 0
	level_earned = 0
	notify()
end

return M
