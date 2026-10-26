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
		BOSS = "BOSS",
		TAP = "TAP!",
		FREE = "FREE",
		TUT_BUY = "Tap to recruit",
		TUT_MERGE = "Drag onto twin",
		TUT_FIGHT = "Fight!",
	},
	[M.LANG_PT] = {
		VICTORY = "VITORIA",
		DEFEAT = "DERROTA",
		NEW = "NOVO!",
		BOSS = "CHEFE",
		TAP = "TOQUE!",
		FREE = "GRATIS",
		TUT_BUY = "Toque para recrutar",
		TUT_MERGE = "Arraste no gêmeo",
		TUT_FIGHT = "Lutar!",
	},
	[M.LANG_RU] = {
		VICTORY = "ПОБЕДА",
		DEFEAT = "ПОРАЖЕНИЕ",
		NEW = "НОВЫЙ!",
		BOSS = "БОСС",
		TAP = "ТАПАЙ!",
		FREE = "ДАРОМ",
		TUT_BUY = "Тапни — найми",
		TUT_MERGE = "Тяни на близнеца",
		TUT_FIGHT = "В бой!",
	},
	[M.LANG_TR] = {
		VICTORY = "ZAFER",
		DEFEAT = "YENILGI",
		NEW = "YENI!",
		BOSS = "BOSS",
		TAP = "DOKUN!",
		FREE = "BEDAVA",
		TUT_BUY = "Asker al",
		TUT_MERGE = "Ikizine surukle",
		TUT_FIGHT = "Savas!",
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
