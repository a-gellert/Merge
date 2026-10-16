local config = require("main.modules.config")

local M = {}

local MELEE = config.UNIT_MELEE
local ARCHER = config.UNIT_ARCHER

M.LEVELS = {
	-- Level 1: Tutorial (1 enemy melee T1 vs 1 player melee T1 + buy & merge to T2)
	[1] = {
		is_tutorial = true,
		win_reward = 30,
		enemies = {
			{ row = 2, col = 2, unit_type = MELEE, tier = 1 },
		},
		initial_player = {
			{ row = 3, col = 2, unit_type = MELEE, tier = 1 },
		}
	},
	-- Level 2: Two enemy melee T1 (Player merges into T3)
	[2] = {
		win_reward = 40,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 1 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 1 },
		}
	},
	-- Level 3: Introduce enemy archer T2 + melee T2 (Player merges into T4)
	[3] = {
		win_reward = 60,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 2 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 2 },
		}
	},
	-- Level 4: Плавный переход без ваншота игрока на первой минуте
	[4] = {
		win_reward = 110,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 3 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 2 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 2 },
		}
	},
	-- Level 5: Первый мини-босс Т4
	[5] = {
		win_reward = 150,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 4 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 3 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 3 },
		}
	},
	-- Level 6: Enemy Tier 5 boss appearance! (Player unlocks Tier 6)
	[6] = {
		win_reward = 180,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 5 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 4 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 4 },
		}
	},
	-- Level 7: Dual Tier 5 enemies + Archer support (Player fields T6 + T5)
	[7] = {
		win_reward = 240,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 5 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 5 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 5 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 4 },
		}
	},
	-- Level 8: Tier 6 Warlord + Tier 5 bodyguards (Player unlocks first Tier 7!)
	[8] = {
		win_reward = 320,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 6 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 5 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 5 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 5 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 5 },
		}
	},
	-- Level 9: Dual Tier 6 frontliners + Heavy archers (Player builds second Tier 7)
	[9] = {
		win_reward = 420,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 6 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 6 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 5 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 6 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 5 },
		}
	},
	-- Level 10: Epic Milestone! Enemy Tier 7 Titan + Tier 6 army (Player has multiple Tier 7 + support)
	[10] = {
		win_reward = 550,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 7 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 6 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 6 },
			{ row = 2, col = 4, unit_type = MELEE, tier = 5 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 6 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 6 },
		}
	},
	-- Level 11: Twin Tier 6 frontliners + Tier 5 sharpshooter
	[11] = {
		win_reward = 620,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 6 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 6 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 5 },
			{ row = 3, col = 4, unit_type = ARCHER, tier = 5 },
		}
	},
	-- Level 12: Tier 7 Vanguard + Crossfire Archers
	[12] = {
		win_reward = 700,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 7 },
			{ row = 2, col = 3, unit_type = MELEE, tier = 6 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 6 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 5 },
		}
	},
	-- Level 13: Tier 7 Twin Shields + Heavy Archer Battery
	[13] = {
		win_reward = 780,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 7 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 6 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 6 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 6 },
			{ row = 3, col = 4, unit_type = ARCHER, tier = 6 },
		}
	},
	-- Level 14: Tier 7 Frontline + Dual Tier 7 Archers
	[14] = {
		win_reward = 860,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 7 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 7 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 7 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 6 },
		}
	},
	-- Level 15: Midgame Boss Wave (Tier 8 Overlord + Tier 7 Elite Guards)
	[15] = {
		win_reward = 980,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 8 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 7 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 6 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 7 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 7 },
		}
	},
	-- Level 16: Frontline regroup (Tri-Melee wall)
	[16] = {
		win_reward = 1060,
		enemies = {
			{ row = 1, col = 1, unit_type = MELEE, tier = 7 },
			{ row = 1, col = 2, unit_type = MELEE, tier = 8 },
			{ row = 1, col = 4, unit_type = MELEE, tier = 7 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 7 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 7 },
		}
	},
	-- Level 17: Dual Tier 8 Spearhead
	[17] = {
		win_reward = 1150,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 8 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 8 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 7 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 7 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 8 },
		}
	},
	-- Level 18: Flankers & Center Juggernaut
	[18] = {
		win_reward = 1250,
		enemies = {
			{ row = 1, col = 1, unit_type = MELEE, tier = 7 },
			{ row = 1, col = 4, unit_type = MELEE, tier = 7 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 8 },
			{ row = 2, col = 3, unit_type = MELEE, tier = 8 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 8 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 7 },
		}
	},
	-- Level 19: Tri-archer battery behind Heavy Guard
	[19] = {
		win_reward = 1350,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 8 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 8 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 8 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 8 },
			{ row = 3, col = 4, unit_type = ARCHER, tier = 8 },
		}
	},
	-- Level 20: Boss Wave (Tier 9 Leviathan + Tier 8 Sharpshooters) - Tough wall!
	[20] = {
		win_reward = 1500,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 9 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 8 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 7 },
			{ row = 2, col = 4, unit_type = MELEE, tier = 7 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 8 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 8 },
		}
	},
	-- Level 21: Twin Tier 8 shock troops + Dual Tier 8 Archers
	[21] = {
		win_reward = 1620,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 8 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 8 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 8 },
			{ row = 4, col = 1, unit_type = ARCHER, tier = 8 },
			{ row = 4, col = 4, unit_type = ARCHER, tier = 8 },
		}
	},
	-- Level 22: Quad frontline barricade
	[22] = {
		win_reward = 1750,
		enemies = {
			{ row = 1, col = 1, unit_type = MELEE, tier = 8 },
			{ row = 1, col = 2, unit_type = MELEE, tier = 9 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 8 },
			{ row = 1, col = 4, unit_type = MELEE, tier = 8 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 8 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 8 },
		}
	},
	-- Level 23: Armored phalanx & Tier 9 sniper crossfire
	[23] = {
		win_reward = 1900,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 9 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 8 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 8 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 8 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 9 },
			{ row = 3, col = 4, unit_type = ARCHER, tier = 8 },
		}
	},
	-- Level 24: Dual Tier 9 vanguard assault
	[24] = {
		win_reward = 2050,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 9 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 9 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 8 },
			{ row = 2, col = 4, unit_type = MELEE, tier = 8 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 9 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 8 },
		}
	},
	-- Level 25: Boss Wave (Tier 10 God of War + Tier 9 Veteran Snipers)
	[25] = {
		win_reward = 2300,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 10 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 9 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 8 },
			{ row = 4, col = 1, unit_type = ARCHER, tier = 9 },
			{ row = 4, col = 4, unit_type = ARCHER, tier = 9 },
		}
	},
	-- Level 26: Iron curtain formation (Full frontline wall)
	[26] = {
		win_reward = 2500,
		enemies = {
			{ row = 1, col = 1, unit_type = MELEE, tier = 9 },
			{ row = 1, col = 2, unit_type = MELEE, tier = 9 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 9 },
			{ row = 1, col = 4, unit_type = MELEE, tier = 9 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 9 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 9 },
		}
	},
	-- Level 27: Heavy Tier 10 Vanguard + Tier 9 Archer Trio
	[27] = {
		win_reward = 2700,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 10 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 9 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 9 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 9 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 9 },
			{ row = 4, col = 4, unit_type = ARCHER, tier = 9 },
		}
	},
	-- Level 28: Twin Titan Frontline (Dual Tier 10 Melee)
	[28] = {
		win_reward = 3000,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 10 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 10 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 9 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 9 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 10 },
			{ row = 4, col = 4, unit_type = ARCHER, tier = 9 },
		}
	},
	-- Level 29: Full Royal Guard Fortress
	[29] = {
		win_reward = 3300,
		enemies = {
			{ row = 1, col = 1, unit_type = MELEE, tier = 10 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 10 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 9 },
			{ row = 2, col = 4, unit_type = MELEE, tier = 9 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 10 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 10 },
		}
	},
	-- Level 30: Final Overlord Boss Wave (All-Star Titan Army)
	[30] = {
		win_reward = 4000,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 10 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 10 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 10 },
			{ row = 2, col = 4, unit_type = MELEE, tier = 9 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 10 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 10 },
		}
	}
}

function M.get_level(level_num)
	local count = #M.LEVELS
	if level_num <= count then
		return M.LEVELS[level_num]
	end
	-- Endless scaling after level 30
	local extra = level_num - count
	local base_tier = math.min(config.MAX_TIER, 8 + math.floor(extra / 4))
	return {
		win_reward = 4000 + extra * 150,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = config.MAX_TIER },
			{ row = 1, col = 3, unit_type = MELEE, tier = base_tier },
			{ row = 2, col = 1, unit_type = MELEE, tier = base_tier },
			{ row = 2, col = 4, unit_type = MELEE, tier = base_tier },
			{ row = 4, col = 2, unit_type = ARCHER, tier = base_tier },
			{ row = 4, col = 3, unit_type = ARCHER, tier = base_tier },
		}
	}
end

return M
