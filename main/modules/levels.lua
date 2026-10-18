local config = require("main.modules.config")

local M = {}

local MELEE = config.UNIT_MELEE
local ARCHER = config.UNIT_ARCHER
M.LEVELS = {
	-- =========================================================================
	-- ВОЛНА 1 (Уровни 1–5): Быстрый разгон (0:00 – 1:30) -> Цель: собрать Т4
	-- =========================================================================

	-- Level 1: Мгновенный экшен со старта (сразу даем пару Т1 + лучника и 25 монет на покупки)
	[1] = {
		is_tutorial = true,
		win_reward = 15,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 1 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 1 },
		},
		initial_player = {
			{ row = 3, col = 2, unit_type = MELEE, tier = 1 },
			{ row = 2, col = 2, unit_type = ARCHER, tier = 1 },
		}
	},
	-- Level 2: Разгон (игрок покупает еще 2 отряда, мерджит Т2-Т3 и получает сундук)
	[2] = {
		win_reward = 25,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 2 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 1 },
		}
	},
	-- Level 3: Знакомство с позиционкой (Т2 фронт + Т2 лучник)
	[3] = {
		win_reward = 40,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 2 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 1 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 2 },
		}
	},
	-- Level 4: Предбоссовое напряжение (появляется капитан Т3, но без ваншота)
	[4] = {
		win_reward = 50,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 3 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 2 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 2 },
		}
	},
	-- Level 5: [БОСС ВОЛНЫ 1] — Командир Т4 + охрана Т2
	[5] = {
		win_reward = 80,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 4 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 2 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 4 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 2 },
		}
	},

	-- =========================================================================
	-- ВОЛНА 2 (Уровни 6–10): Сборка Золотого Т5 и выход к Т6 (1:30 – 4:00)
	-- =========================================================================

	-- Level 6: [ЯМА РАЗРЯДКИ / ТРИУМФ] — Никаких Т4 и Т5! Широкая шеренга Т2 пехоты и лучников (-34% сложности).
	-- Игрок выносит их своим новым Т4 за считанные секунды и фармит кучу монет!
	[6] = {
		win_reward = 120,
		enemies = {
			{ row = 1, col = 1, unit_type = MELEE, tier = 2 },
			{ row = 1, col = 2, unit_type = MELEE, tier = 2 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 2 },
			{ row = 1, col = 4, unit_type = MELEE, tier = 2 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 2 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 2 },
		}
	},
	-- Level 7: Плавный возврат к Т4 (фланговые стрелки)
	[7] = {
		win_reward = 150,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 4 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 3 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 3 },
			{ row = 3, col = 4, unit_type = ARCHER, tier = 3 },
		}
	},
	-- Level 8: Два танка Т4 + прикрытие лучников
	[8] = {
		win_reward = 200,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 4 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 4 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 4 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 3 },
		}
	},
	-- Level 9: Предбоссовое напряжение (появляется первый Т5 врага)
	[9] = {
		win_reward = 250,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 5 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 4 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 4 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 4 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 4 },
		}
	},
	-- Level 10: [БОСС ВОЛНЫ 2] — Воевода Т6 + гвардия Т5
	[10] = {
		win_reward = 300,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 6 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 5 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 4 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 5 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 4 },
		}
	},

	-- =========================================================================
	-- ВОЛНА 3 (Уровни 11–15): Мидгейм и первый Рубиновый Т7 (4:00 – 8:00)
	-- =========================================================================

	-- Level 11: [ЯМА РАЗРЯДКИ / ТРИУМФ] — Спад сложности на 27% после Босса 10!
	-- Командир Т5 в центре + шеренга Т4 и стрелки Т3 (никаких Т6).
	[11] = {
		win_reward = 400,
		enemies = {
			{ row = 1, col = 1, unit_type = MELEE, tier = 4 },
			{ row = 1, col = 2, unit_type = MELEE, tier = 5 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 4 },
			{ row = 1, col = 4, unit_type = MELEE, tier = 4 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 3 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 3 },
		}
	},
	-- Level 12: Возврат Т6 в авангард + перекрестный огонь
	[12] = {
		win_reward = 450,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 6 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 5 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 5 },
			{ row = 3, col = 4, unit_type = ARCHER, tier = 5 },
		}
	},
	-- Level 13: Батарея из трех лучников Т5 за спиной двух танков Т6
	[13] = {
		win_reward = 500,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 6 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 6 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 5 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 6 },
			{ row = 3, col = 4, unit_type = ARCHER, tier = 5 },
		}
	},
	-- Level 14: Напряжение перед боссом (плотный строй Т6)
	[14] = {
		win_reward = 600,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 6 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 6 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 6 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 6 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 6 },
		}
	},
	-- Level 15: [БОСС ВОЛНЫ 3] — Титан Т7 + Элитная стража Т6
	[15] = {
		win_reward = 600,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 7 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 6 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 6 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 6 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 6 },
		}
	},

	-- =========================================================================
	-- ВОЛНА 4 (Уровни 16–20): Масштабные сражения толп (8:00 – 13:00)
	-- =========================================================================

	-- Level 16: [ЯМА РАЗРЯДКИ / ТРИУМФ] — Спад сложности на 32% после Босса 15!
	-- Командир Т6 в центре + шеренга Т5 пехоты и лучников (без Т7).
	[16] = {
		win_reward = 720,
		enemies = {
			{ row = 1, col = 1, unit_type = MELEE, tier = 5 },
			{ row = 1, col = 2, unit_type = MELEE, tier = 6 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 5 },
			{ row = 1, col = 4, unit_type = MELEE, tier = 5 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 5 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 5 },
		}
	},
	-- Level 17: Острие копья (Т7 в центре + снайперы Т6)
	[17] = {
		win_reward = 800,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 7 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 6 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 6 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 6 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 7 },
		}
	},
	-- Level 18: Двойной щит Т7 + авангард Т6
	[18] = {
		win_reward = 870,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 6 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 7 },
			{ row = 2, col = 3, unit_type = MELEE, tier = 7 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 7 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 6 },
		}
	},
	-- Level 19: Предбоссовый штурм (Стена Т7 + батарея стрелков Т7/Т6)
	[19] = {
		win_reward = 950,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 7 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 7 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 6 },
			{ row = 3, col = 4, unit_type = ARCHER, tier = 6 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 7 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 7 },
		}
	},
	-- Level 20: [БОСС ВОЛНЫ 4] — Оверлорд Т8 + телохранители Т7
	[20] = {
		win_reward = 1100,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 8 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 7 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 6 },
			{ row = 2, col = 4, unit_type = MELEE, tier = 6 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 7 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 7 },
		}
	},

	-- =========================================================================
	-- ВОЛНА 5 (Уровни 21–25): Поход к Левиафану Т9 (13:00 – 19:00)
	-- =========================================================================

	-- Level 21: [ЯМА РАЗРЯДКИ / ТРИУМФ] — Спад сложности на 34% после Босса 20!
	-- Командир Т7 в центре + строй Т6 пехоты и лучников (без Т8).
	[21] = {
		win_reward = 1215,
		enemies = {
			{ row = 1, col = 1, unit_type = MELEE, tier = 6 },
			{ row = 1, col = 2, unit_type = MELEE, tier = 7 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 6 },
			{ row = 1, col = 4, unit_type = MELEE, tier = 6 },
			{ row = 4, col = 1, unit_type = ARCHER, tier = 6 },
			{ row = 4, col = 4, unit_type = ARCHER, tier = 6 },
		}
	},
	-- Level 22: Возврат Т8 в центр баррикады
	[22] = {
		win_reward = 1300,
		enemies = {
			{ row = 1, col = 1, unit_type = MELEE, tier = 7 },
			{ row = 1, col = 2, unit_type = MELEE, tier = 8 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 7 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 7 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 8 },
		}
	},
	-- Level 23: Бронированная фаланга Т8 + снайперский огонь
	[23] = {
		win_reward = 1500,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 8 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 8 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 7 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 7 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 8 },
			{ row = 3, col = 4, unit_type = ARCHER, tier = 7 },
		}
	},
	-- Level 24: Тяжелый штурм (Два Т8 спереди + Два лучника Т8 сзади)
	[24] = {
		win_reward = 1700,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 8 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 8 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 7 },
			{ row = 2, col = 4, unit_type = MELEE, tier = 7 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 8 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 8 },
		}
	},
	-- Level 25: [БОСС ВОЛНЫ 5] — Левиафан Т9 + элита Т8
	[25] = {
		win_reward = 1800,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 9 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 8 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 8 },
			{ row = 4, col = 1, unit_type = ARCHER, tier = 8 },
			{ row = 4, col = 4, unit_type = ARCHER, tier = 8 },
		}
	},

	-- =========================================================================
	-- ВОЛНА 6 (Уровни 26–30): Финальный рывок к Богу Войны Т10 (19:00 – 25:00+)
	-- =========================================================================

	-- Level 26: [ЯМА РАЗРЯДКИ / ТРИУМФ] — Спад сложности на 31% после Босса 25!
	-- Командир Т8 в центре + шеренга Т7 пехоты и лучников (без Т9) для фарма перед финалом.
	[26] = {
		win_reward = 1900,
		enemies = {
			{ row = 1, col = 1, unit_type = MELEE, tier = 7 },
			{ row = 1, col = 2, unit_type = MELEE, tier = 8 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 7 },
			{ row = 1, col = 4, unit_type = MELEE, tier = 7 },
			{ row = 3, col = 2, unit_type = ARCHER, tier = 7 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 7 },
		}
	},
	-- Level 27: Возврат Т9 в строй + трио стрелков Т8
	[27] = {
		win_reward = 2050,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 9 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 8 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 8 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 8 },
			{ row = 3, col = 3, unit_type = ARCHER, tier = 8 },
			{ row = 4, col = 4, unit_type = ARCHER, tier = 8 },
		}
	},
	-- Level 28: Двойной бастион Т9 + Снайпер Т9
	[28] = {
		win_reward = 2100,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 9 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 9 },
			{ row = 2, col = 2, unit_type = MELEE, tier = 8 },
			{ row = 3, col = 1, unit_type = ARCHER, tier = 8 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 9 },
			{ row = 4, col = 4, unit_type = ARCHER, tier = 8 },
		}
	},
	-- Level 29: Предфинальная королевская гвардия (Появляется первый авангард Т10)
	[29] = {
		win_reward = 2250,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 10 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 9 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 8 },
			{ row = 2, col = 4, unit_type = MELEE, tier = 8 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 9 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 9 },
		}
	},
	-- Level 30: [ФИНАЛЬНЫЙ БОСС КАМПАНИИ] — Два Титана Т10 + Снайпер Т10
	[30] = {
		win_reward = 2500,
		enemies = {
			{ row = 1, col = 2, unit_type = MELEE, tier = 10 },
			{ row = 1, col = 3, unit_type = MELEE, tier = 10 },
			{ row = 2, col = 1, unit_type = MELEE, tier = 9 },
			{ row = 2, col = 4, unit_type = MELEE, tier = 9 },
			{ row = 4, col = 2, unit_type = ARCHER, tier = 10 },
			{ row = 4, col = 3, unit_type = ARCHER, tier = 9 },
		}
	}
}

function M.get_level(level_num)
	local count = #M.LEVELS
	if level_num <= count then
		return M.LEVELS[level_num]
	end
	-- Endless sawtooth scaling after level 30 (5-level repeating wave cycle)
	local extra = level_num - count
	local wave_index = math.floor((extra - 1) / 5)
	local step_in_wave = (extra - 1) % 5 + 1
	local base_tier = math.min(config.MAX_TIER - 2, 7 + math.floor(wave_index / 2))
	local boss_tier = math.min(config.MAX_TIER, base_tier + 2)

	if step_in_wave == 1 then
		-- Sawtooth Trough: relief wave after boss
		return {
			win_reward = 2800 + extra * 120,
			enemies = {
				{ row = 1, col = 1, unit_type = MELEE, tier = base_tier },
				{ row = 1, col = 2, unit_type = MELEE, tier = base_tier + 1 },
				{ row = 1, col = 3, unit_type = MELEE, tier = base_tier },
				{ row = 1, col = 4, unit_type = MELEE, tier = base_tier },
				{ row = 4, col = 2, unit_type = ARCHER, tier = base_tier },
				{ row = 4, col = 3, unit_type = ARCHER, tier = base_tier },
			}
		}
	elseif step_in_wave == 5 then
		-- Sawtooth Peak: Endless Boss
		return {
			win_reward = 4000 + extra * 150,
			enemies = {
				{ row = 1, col = 2, unit_type = MELEE, tier = boss_tier },
				{ row = 1, col = 3, unit_type = MELEE, tier = boss_tier },
				{ row = 2, col = 1, unit_type = MELEE, tier = base_tier + 1 },
				{ row = 2, col = 4, unit_type = MELEE, tier = base_tier + 1 },
				{ row = 4, col = 2, unit_type = ARCHER, tier = boss_tier },
				{ row = 4, col = 3, unit_type = ARCHER, tier = base_tier + 1 },
			}
		}
	else
		-- Steps 2, 3, 4: ascending ramp
		local ramp_tier = math.min(config.MAX_TIER, base_tier + (step_in_wave >= 3 and 1 or 0))
		return {
			win_reward = 3000 + extra * 130,
			enemies = {
				{ row = 1, col = 2, unit_type = MELEE, tier = ramp_tier + 1 },
				{ row = 1, col = 3, unit_type = MELEE, tier = ramp_tier },
				{ row = 2, col = 1, unit_type = MELEE, tier = base_tier },
				{ row = 2, col = 4, unit_type = MELEE, tier = base_tier },
				{ row = 4, col = 2, unit_type = ARCHER, tier = ramp_tier },
				{ row = 4, col = 3, unit_type = ARCHER, tier = base_tier },
			}
		}
	end
end

return M
