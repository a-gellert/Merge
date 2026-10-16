local M = {}

M.LANG_EN = "en"
M.LANG_PT = "pt"
M.LANG_RU = "ru"
M.LANG_TR = "tr"

local current_language = M.LANG_EN

local STRINGS = {
	[M.LANG_EN] = {
		BUY = "BUY",
		BATTLE = "BATTLE",
		AUTO_MERGE = "AUTO",
		LEVEL = "LEVEL",
		VICTORY = "VICTORY!",
		DEFEAT = "DEFEAT!",
		RETRY = "RETRY",
		NEXT = "NEXT",
		COINS = "COINS",
		CONGRATS = "EXCELLENT!",
		REWARD = "FREE",
		TUTORIAL_BUY = "Tap Buy to summon a warrior",
		TUTORIAL_MERGE = "Drag and merge squads",
		TUTORIAL_BATTLE = "Tap Battle to fight!",
		DRUM_OF_RAGE = "DRUM OF RAGE +15% SPEED!",
	},
	[M.LANG_PT] = {
		BUY = "COMPRAR",
		BATTLE = "BATALHA",
		AUTO_MERGE = "FUNDIR",
		LEVEL = "NÍVEL",
		VICTORY = "VITÓRIA!",
		DEFEAT = "DERROTA!",
		RETRY = "REPETIR",
		NEXT = "SEGUINTE",
		COINS = "MOEDAS",
		CONGRATS = "MUITO BEM!",
		REWARD = "GRÁTIS",
		TUTORIAL_BUY = "Toque em Comprar para invocar",
		TUTORIAL_MERGE = "Arraste e funda esquadrões",
		TUTORIAL_BATTLE = "Toque em Batalha para lutar!",
		DRUM_OF_RAGE = "TAMBOR DE FÚRIA +15% VELOCIDADE!",
	},
	[M.LANG_RU] = {
		BUY = "КУПИТЬ",
		BATTLE = "В БОЙ",
		AUTO_MERGE = "АВТО",
		LEVEL = "УРОВЕНЬ",
		VICTORY = "ПОБЕДА!",
		DEFEAT = "ПОРАЖЕНИЕ!",
		RETRY = "ЗАНОВО",
		NEXT = "ДАЛЕЕ",
		COINS = "МОНЕТЫ",
		CONGRATS = "ОТЛИЧНО!",
		REWARD = "ПРИЗ",
		TUTORIAL_BUY = "Нажми Купить, чтобы призвать воина",
		TUTORIAL_MERGE = "Перетащи и объедини отряды",
		TUTORIAL_BATTLE = "Нажми В бой!",
		DRUM_OF_RAGE = "БАРАБАН ЯРОСТИ +15% СКОРОСТЬ!",
	},
	[M.LANG_TR] = {
		BUY = "SATIN AL",
		BATTLE = "SAVAŞ",
		AUTO_MERGE = "BİRLEŞTİR",
		LEVEL = "SEVİYE",
		VICTORY = "ZAFER!",
		DEFEAT = "YENİLGİ!",
		RETRY = "TEKRAR DENE",
		NEXT = "SONRAKİ",
		COINS = "ALTIN",
		CONGRATS = "HARİKA!",
		REWARD = "ÜCRETSİZ",
		TUTORIAL_BUY = "Savaşçı çağırmak için Satın Al'a bas",
		TUTORIAL_MERGE = "Birlikleri sürükleyip birleştir",
		TUTORIAL_BATTLE = "Savaş'a bas ve başla!",
		DRUM_OF_RAGE = "ÖFKE DAVULU +%15 HIZ!",
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
