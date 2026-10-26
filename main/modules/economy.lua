local config = require("main.modules.config")

local M = {}

local coins = config.START_COINS
local displayed_coins = config.START_COINS
local best_tier = 1        -- highest tier ever owned (drives shop tier)
local level_buys = 0       -- purchases made during the current level
local level_earned = 0
local on_change_callbacks = {}
local on_earn_callbacks = {}

local function notify()
	local disp = math.floor(displayed_coins)
	for i = 1, #on_change_callbacks do
		on_change_callbacks[i](disp)
	end
end

function M.get_coins()
	return coins
end

function M.get_displayed_coins()
	return math.floor(displayed_coins)
end

function M.get_best_tier()
	return best_tier
end

function M.register_tier(tier)
	if tier > best_tier then
		best_tier = tier
		notify()
		return true
	end
	return false
end

-- Tier the shop sells right now
function M.get_shop_tier()
	return math.max(1, best_tier - config.SHOP_GAP)
end

function M.get_buy_cost()
	local value = config.get_tier_value(M.get_shop_tier())
	return math.floor(config.PRICE_BASE * value * config.PRICE_LEVEL_STEP ^ level_buys + 0.5)
end

function M.can_afford_buy()
	return coins >= M.get_buy_cost()
end

function M.get_level_buys()
	return level_buys
end

function M.new_level()
	level_buys = 0
	level_earned = 0
	notify()
end

function M.set_state(saved_coins, saved_best_tier, saved_level_buys)
	coins = tonumber(saved_coins) or config.START_COINS
	displayed_coins = coins
	best_tier = tonumber(saved_best_tier) or 1
	level_buys = tonumber(saved_level_buys) or 0
	notify()
end

function M.get_level_earned()
	return level_earned
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
	amount = math.floor(amount + 0.5)
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
	if math.abs(diff) <= 0.5 then
		displayed_coins = coins
		notify()
		return
	end

	-- Counter rolls up quickly (~0.5s) so rewards feel tangible
	local speed = math.max(10, math.abs(diff) * 6.0)
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
	level_buys = level_buys + 1
	notify()
	return true
end

function M.reset()
	coins = config.START_COINS
	displayed_coins = coins
	best_tier = 1
	level_buys = 0
	level_earned = 0
	notify()
end

return M
