local config = require("main.modules.config")

local M = {}

local MELEE = config.UNIT_MELEE
local ARCHER = config.UNIT_ARCHER

M.LEVELS = {
	-- Level 1: Tutorial (1 enemy melee T1 vs 1 player melee T1 + buy & merge)
	[1] = {
		is_tutorial = true,
		win_reward = 25,
		enemies = {
			{ row = 2, col = 2, unit_type = MELEE, tier = 1 },
		},
		initial_player = {
			{ row = 3, col = 2, unit_type = MELEE, tier = 1 },
		}
	},
	-- Level 2: Two enemy melee T1
	[2] = {
		win_reward = 20,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 1 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 1 },
		}
	},
	-- Level 3: Introduce enemy archer
	[3] = {
		win_reward = 25,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 1 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 1 },
		}
	},
	-- Level 4: Two melee T1 + one archer T1
	[4] = {
		win_reward = 30,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 1 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 1 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 1 },
		}
	},
	-- Level 5: Tier 2 enemy melee appears
	[5] = {
		win_reward = 35,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 2 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 1 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 1 },
		}
	},
	-- Level 6: Two melee T2 + one archer T1
	[6] = {
		win_reward = 40,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 2 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 2 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 1 },
		}
	},
	-- Level 7: Balanced T2 squad
	[7] = {
		win_reward = 45,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 2 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 1 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 2 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 1 },
		}
	},
	-- Level 8: Two melee T2 + two archer T2
	[8] = {
		win_reward = 50,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 2 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 2 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 2 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 2 },
		}
	},
	-- Level 9: Tier 3 melee captain
	[9] = {
		win_reward = 60,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 3 },
			{ row = 2, col = 3, unit_type = MELEE, tier = 2 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 2 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 2 },
		}
	},
	-- Level 10: Wide frontline + archer backline
	[10] = {
		win_reward = 70,
		enemies = {
			{ row = 1, col = 1, unit_type = MELEE, tier = 2 },
			{ row = 1, col = 2, unit_type = MELEE, tier = 3 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 2 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 3 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 2 },
		}
	},
	-- Level 11: Twin Tier 3 frontliners
	[11] = {
		win_reward = 80,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 3 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 3 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 2 },
			{ row = 3, col = 4, unit_type = ARCHER, tier = 3 },
		}
	},
	-- Level 12: Tier 4 elite vanguard
	[12] = {
		win_reward = 90,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 4 },
			{ row = 2, col = 3, unit_type = MELEE, tier = 3 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 3 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 3 },
		}
	},
	-- Level 13: Heavy archer barrage
	[13] = {
		win_reward = 100,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 4 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 3 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 3 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 3 },
			{ row = 3, col = 4, unit_type = ARCHER, tier = 3 },
		}
	},
	-- Level 14: Royal guard formation
	[14] = {
		win_reward = 115,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 4 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 4 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 4 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 3 },
		}
	},
	-- Level 15: Boss Wave (Tier 5 commander + Tier 4 guards)
	[15] = {
		win_reward = 150,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 5 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 4 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 3 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 4 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 4 },
		}
	},
	-- Level 16: Heavy frontline regroup
	[16] = {
		win_reward = 165,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 4 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 4 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 3 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 4 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 4 },
		}
	},
	-- Level 17: Vanguard spearhead
	[17] = {
		win_reward = 180,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 5 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 3 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 3 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 4 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 4 },
		}
	},
	-- Level 18: Flankers & center juggernaut
	[18] = {
		win_reward = 200,
		enemies = {
			{ row = 1, col = 1, unit_type = MELEE, tier = 4 },
			{ row = 1, col = 4, unit_type = MELEE, tier = 4 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 5 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 4 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 4 },
		}
	},
	-- Level 19: Tri-archer firing battery
	[19] = {
		win_reward = 220,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 5 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 4 },
			{ row = 2, col = 3, unit_type = MELEE, tier = 4 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 4 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 4 },
			{ row = 4, col = 4, unit_type = ARCHER, tier = 4 },
		}
	},
	-- Level 20: Boss Wave (Tier 6 Colossus + Tier 5 sharpshooter)
	[20] = {
		win_reward = 260,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 6 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 4 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 4 },
			{ row = 4, col = 1, unit_type = ARCHER, tier = 4 },
			{ row = 4, col = 4, unit_type = ARCHER, tier = 5 },
		}
	},
	-- Level 21: Twin Tier 5 shock troops
	[21] = {
		win_reward = 285,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 5 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 5 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 4 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 5 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 4 },
		}
	},
	-- Level 22: Tri-tank shield line
	[22] = {
		win_reward = 310,
		enemies = {
			{ row = 1, col = 1, unit_type = MELEE, tier = 5 },
			{ row = 1, col = 2, unit_type = MELEE, tier = 5 },
			{ row = 1, col = 4, unit_type = MELEE, tier = 5 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 5 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 5 },
		}
	},
	-- Level 23: Armored phalanx & crossfire
	[23] = {
		win_reward = 340,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 6 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 5 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 5 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 5 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 5 },
			{ row = 3, col = 4, unit_type = ARCHER, tier = 4 },
		}
	},
	-- Level 24: Dual Tier 6 vanguard
	[24] = {
		win_reward = 375,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 6 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 6 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 4 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 5 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 5 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 5 },
		}
	},
	-- Level 25: Boss Wave (Tier 7 Titan + Tier 6 Grand Sniper)
	[25] = {
		win_reward = 420,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 7 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 5 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 5 },
			{ row = 4, col = 1, unit_type = ARCHER, tier = 6 },
			{ row = 4, col = 4, unit_type = ARCHER, tier = 5 },
		}
	},
	-- Level 26: Iron curtain formation
	[26] = {
		win_reward = 460,
		enemies = {
			{ row = 1, col = 1, unit_type = MELEE, tier = 6 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 6 },
			{ row = 1, col = 4, unit_type = MELEE, tier = 5 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 6 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 5 },
		}
	},
	-- Level 27: Heavy Tier 7 assault
	[27] = {
		win_reward = 500,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 7 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 6 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 5 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 6 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 6 },
			{ row = 4, col = 4, unit_type = ARCHER, tier = 5 },
		}
	},
	-- Level 28: Twin Titan frontline
	[28] = {
		win_reward = 550,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 7 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 7 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 6 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 6 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 6 },
			{ row = 4, col = 4, unit_type = ARCHER, tier = 6 },
		}
	},
	-- Level 29: Full royal defense
	[29] = {
		win_reward = 600,
		enemies = {
			{ row = 1, col = 1, unit_type = MELEE, tier = 7 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 7 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 6 },
			{ row = 2, col = 4, unit_type = MELEE, tier = 6 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 7 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 6 },
		}
	},
	-- Level 30: Final Boss Wave (Tier 8 Overlord + Tier 7 Royal Guard)
	[30] = {
		win_reward = 750,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 8 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 7 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 6 },
			{ row = 2, col = 4, unit_type = MELEE, tier = 6 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 7 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 7 },
		}
	}
}

function M.get_level(level_num)
	local count = #M.LEVELS
	if level_num <= count then
		return M.LEVELS[level_num]
	end
	-- Endless scaling after level 15
	local extra = level_num - count
	local base_tier = math.min(config.MAX_TIER - 1, 4 + math.floor(extra / 3))
	return {
		win_reward = 150 + extra * 20,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = math.min(config.MAX_TIER, base_tier + 1) },
			{ row = 1, col = 3, unit_type = MELEE, tier = base_tier },
			{ row = 2, col = 1, unit_type = MELEE, tier = base_tier },
			{ row = 2, col = 4, unit_type = MELEE, tier = base_tier },
			{ row = 4, col = 2, unit_type = ARCHER, tier = base_tier },
			{ row = 4, col = 3, unit_type = ARCHER, tier = base_tier },
		}
	}
end

return M
