local M = {}

local SAVE_FILENAME = "merge_game_save"

function M.get_save_path()
	return sys.get_save_file(SAVE_FILENAME, "save.dat")
end

function M.save(data)
	local path = M.get_save_path()
	local success = sys.save(path, data)
	return success
end

function M.load()
	local path = M.get_save_path()
	local data = sys.load(path)
	if not data or next(data) == nil then
		return nil
	end
	return data
end

return M
