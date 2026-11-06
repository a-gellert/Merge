local M = {}

M.LANG_EN = "en"
M.LANG_PT = "pt"
M.LANG_RU = "ru"
M.LANG_TR = "tr"

local current_language = M.LANG_EN

local STRINGS = {
	[M.LANG_EN] = {
		VICTORY = "VICTORY",
		DEFEAT = "DEFEAT",
		NEW = "NEW!",
		NEW_TIER = "NEW TIER!",
		BOSS = "BOSS",
		TAP = "TAP!",
		FREE = "FREE",
		TUT_BUY = "Tap to recruit",
		TUT_MERGE = "Drag onto twin",
		TUT_FIGHT = "Fight!",
		TALENTS = "TALENTS",
		TALENT_MELEE_NAME = "Melee",
		TALENT_MELEE_DESC = "+5% HP & DPS",
		TALENT_ARCHER_NAME = "Archers",
		TALENT_ARCHER_DESC = "+5% DPS",
		TALENT_GOLD_NAME = "Bounty",
		TALENT_GOLD_DESC = "+8% Gold",
		TALENT_START_NAME = "Capital",
		TALENT_START_DESC = "+10 Coins",
		TALENT_LV = "Lv. {lv}",
		MAX = "MAX",
	},
	[M.LANG_PT] = {
		VICTORY = "VITORIA",
		DEFEAT = "DERROTA",
		NEW = "NOVO!",
		NEW_TIER = "NOVO TIER!",
		BOSS = "CHEFE",
		TAP = "TOQUE!",
		FREE = "GRATIS",
		TUT_BUY = "Toque para recrutar",
		TUT_MERGE = "Arraste no gemeo",
		TUT_FIGHT = "Lutar!",
		TALENTS = "TALENTOS",
		TALENT_MELEE_NAME = "Guerreiros",
		TALENT_MELEE_DESC = "+5% Vida & DPS",
		TALENT_ARCHER_NAME = "Arqueiros",
		TALENT_ARCHER_DESC = "+5% DPS",
		TALENT_GOLD_NAME = "Recompensa",
		TALENT_GOLD_DESC = "+8% Ouro",
		TALENT_START_NAME = "Capital",
		TALENT_START_DESC = "+10 Moedas",
		TALENT_LV = "Niv. {lv}",
		MAX = "MAX",
	},
	[M.LANG_RU] = {
		VICTORY = "ПОБЕДА",
		DEFEAT = "ПОРАЖЕНИЕ",
		NEW = "НОВЫЙ!",
		NEW_TIER = "НОВЫЙ ТИР!",
		BOSS = "БОСС",
		TAP = "ТАПАЙ!",
		FREE = "ДАРОМ",
		TUT_BUY = "Тапни — найми",
		TUT_MERGE = "Тяни на близнеца",
		TUT_FIGHT = "В бой!",
		TALENTS = "ТАЛАНТЫ",
		TALENT_MELEE_NAME = "Мечники",
		TALENT_MELEE_DESC = "+5% HP и урон",
		TALENT_ARCHER_NAME = "Лучники",
		TALENT_ARCHER_DESC = "+5% урон",
		TALENT_GOLD_NAME = "Добыча",
		TALENT_GOLD_DESC = "+8% золота",
		TALENT_START_NAME = "Капитал",
		TALENT_START_DESC = "+10 на старте",
		TALENT_LV = "Ур. {lv}",
		MAX = "МАКС",
	},
	[M.LANG_TR] = {
		VICTORY = "ZAFER",
		DEFEAT = "YENILGI",
		NEW = "YENI!",
		NEW_TIER = "YENI ASAMA!",
		BOSS = "BOSS",
		TAP = "DOKUN!",
		FREE = "BEDAVA",
		TUT_BUY = "Asker al",
		TUT_MERGE = "Ikizine surukle",
		TUT_FIGHT = "Savas!",
		TALENTS = "YETENEKLER",
		TALENT_MELEE_NAME = "Savasci",
		TALENT_MELEE_DESC = "+5% Can & Hasar",
		TALENT_ARCHER_NAME = "Okcular",
		TALENT_ARCHER_DESC = "+5% Hasar",
		TALENT_GOLD_NAME = "Ganimet",
		TALENT_GOLD_DESC = "+8% Altin",
		TALENT_START_NAME = "Sermaye",
		TALENT_START_DESC = "+10 Baslangic",
		TALENT_LV = "Sv. {lv}",
		MAX = "MAKS",
	},
}

local function detect_language()
	local sys_info = sys.get_sys_info()
	local lang = sys_info and sys_info.language
	if not lang then return M.LANG_EN end
	lang = string.lower(string.sub(lang, 1, 2))
	if STRINGS[lang] then
		return lang
	end
	return M.LANG_EN
end

current_language = detect_language()

function M.set_language(lang)
	if STRINGS[lang] then
		current_language = lang
	else
		current_language = M.LANG_EN
	end
end

function M.get_language()
	return current_language
end

function M.get(key, params)
	local dict = STRINGS[current_language] or STRINGS[M.LANG_EN]
	local text = dict[key] or STRINGS[M.LANG_EN][key] or key
	if params then
		for k, v in pairs(params) do
			text = string.gsub(text, "{" .. tostring(k) .. "}", tostring(v))
		end
	end
	return text
end

return M
