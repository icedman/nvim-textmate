local Map = require("nvim-textmate.colormap")

local info = debug.getinfo(1, "S")
local cpath = package.cpath

local local_path = info.source:gsub("init.lua", ""):gsub("@", "")

package.cpath = package.cpath .. ";" .. local_path .. "textmate.so"

local ok, module = pcall(require, "textmate")

package.cpath = cpath

if not ok then
	return {
		setup = function(parameters)
			vim.defer_fn(function()
				local target_path = local_path .. "../../"
				print("Configuring textmate module...")
				vim.fn.system({ "make", "prebuild", "-C", target_path })
				print("Compiling textmate module...")
				vim.fn.system({ "make", "build", "-C", target_path })
				print("Done. Restart neovim.")
			end, 500)
		end,
	}
end

local scope_hl_map = Map.scope_hl_map

function txmt_scope_hl_map()
	vim.pretty_print(scope_hl_map)
end

local api = vim.api
local render_timer = nil
local changed_timer = nil
local buffer_data = {}

local hl_default_timeout = 50
local hl_timeout_next_tick = 0
local hl_timeout_after_change = 150
local hl_timeout_after_language_load = 1500

local enabled = true
local group = api.nvim_create_augroup("textmate", { clear = true })
local loaded_theme = nil
local _txmt_highlight_buffer

-- setup options
local quick_load = false
local theme_name = "Monokai"
local override_colorscheme = false
local debug_scopes = false
local custom_scope_map = nil
local extension_paths = {
	"~/.vscode/extensions/",
	"~/.editor/extensions/",
}

local function load_theme()
	if not override_colorscheme then
		if not loaded_theme then
			module.highlight_load_theme("")
			loaded_theme = "-"
		end
		return
	end

	loaded_theme = theme_name
	if not loaded_theme then
		loaded_theme = "Monokai"
	end
	module.highlight_load_theme(loaded_theme)

	local theme = module.highlight_theme_info()
	local normal_fg = string.format("#%02x%02x%02x", theme[1], theme[2], theme[3])
	local normal_bg = string.format("#%02x%02x%02x", theme[4], theme[5], theme[6])
	local sel_fg = string.format("#%02x%02x%02x", theme[7], theme[8], theme[9])
	local cmt_fg = string.format("#%02x%02x%02x", theme[10], theme[11], theme[12])
	local fn_fg = string.format("#%02x%02x%02x", theme[13], theme[14], theme[15])
	local kw_fg = string.format("#%02x%02x%02x", theme[16], theme[17], theme[18])
	local var_fg = string.format("#%02x%02x%02x", theme[19], theme[20], theme[21])
	local typ_fg = string.format("#%02x%02x%02x", theme[22], theme[23], theme[24])
	local strct_fg = string.format("#%02x%02x%02x", theme[25], theme[26], theme[27])
	local ctrl_fg = string.format("#%02x%02x%02x", theme[28], theme[29], theme[30])
	api.nvim_set_hl(0, "Normal", { bg = normal_bg })
	api.nvim_set_hl(0, "NormalNC", { bg = normal_bg })
	api.nvim_set_hl(0, "LineNr", { fg = cmt_fg })
	api.nvim_set_hl(0, "Comment", { fg = cmt_fg })
	api.nvim_set_hl(0, "Function", { fg = fn_fg })
	api.nvim_set_hl(0, "Statement", { fg = fn_fg })
	api.nvim_set_hl(0, "Method", { fg = fn_fg })
	api.nvim_set_hl(0, "Keyword", { fg = kw_fg })
	api.nvim_set_hl(0, "Define", { fg = kw_fg })
	api.nvim_set_hl(0, "Include", { fg = kw_fg })
	api.nvim_set_hl(0, "Variable", { fg = var_fg })
	api.nvim_set_hl(0, "Identifier", { fg = var_fg })
	api.nvim_set_hl(0, "Boolean", { fg = var_fg })
	api.nvim_set_hl(0, "Character", { fg = var_fg })
	api.nvim_set_hl(0, "String", { fg = var_fg })
	api.nvim_set_hl(0, "Number", { fg = var_fg })
	api.nvim_set_hl(0, "Type", { fg = typ_fg })
	api.nvim_set_hl(0, "Struct", { fg = strct_fg })
	api.nvim_set_hl(0, "Structure", { fg = strct_fg })
	api.nvim_set_hl(0, "StorageClass", { fg = strct_fg })
end

local function setup(parameters)
	quick_load = parameters["quick_load"]
	debug_scopes = parameters["debug_scopes"]
	custom_scope_map = parameters["custom_scope_map"]
	override_colorscheme = parameters["override_colorscheme"]

	if parameters["theme_name"] then
		theme_name = parameters["theme_name"]
	end
	-- if parameters["extension_paths"] then
	-- 	extension_paths = parameters["extension_paths"]
	-- end

	load_theme()
end

local function txmt_initialize()
	for i, ex in ipairs(extension_paths) do
		module.highlight_set_extensions_dir(vim.fn.expand(ex))
	end
	module.highlight_set_extensions_dir(info.source:gsub("init.lua", "extensions/"):gsub("@", ""))
end

local function txmt_free_buffer(b)
	if buffer_data and buffer_data[b] then
		api.nvim_buf_clear_namespace(b, 0, 0, -1)
		buffer_data[b] = nil
	end
	module.highlight_remove_doc(b)
end

local function txmt_set_language(buffer)
	if not enabled then
		return false
	end

	if not loaded_theme then
		load_theme()
	end

	local b = buffer
	if not b then
		b = api.nvim_get_current_buf()
	end

	if not buffer_data[b] then
		buffer_data[b] = {}
	end

	local filetype = vim.bo.filetype
	buffer_data[b]["filetype"] = filetype

	-- should exclude?

	if not buffer_data[b]["langid"] then
		local langid
		local ext = buffer_data[b]["extension"]
		if ext then
			langid = module.highlight_load_language("file" .. ext)
		else
			langid = module.highlight_load_language(vim.fn.expand("%"))
		end
		buffer_data[b]["langid"] = langid
		if langid ~= -1 then
			vim.defer_fn(function()
				_txmt_highlight_buffer()
			end, hl_timeout_after_language_load)
		end
	end

	if buffer_data[b]["langid"] == -1 then
		return false
	end

	module.highlight_set_language(buffer_data[b]["langid"])
	return true
end

local function txmt_highlight_line(n, l, buffer)
	if not enabled then
		return
	end

	if not txmt_set_language(buffer) then
		return
	end

	local b = buffer
	if not b then
		b = api.nvim_get_current_buf()
	end

	local r, c = unpack(vim.api.nvim_win_get_cursor(0))

	api.nvim_buf_clear_namespace(b, 0, n - 1, n)
	local langid = buffer_data[b]["langid"]
	if langid == -1 then
		return
	end

	local t = module.highlight_line(l, n, langid, b)

	if debug_scopes then
		if not buffer_data[b]["scopes"] then
			buffer_data[b]["scopes"] = {}
		end
		buffer_data[b]["scopes"][n] = t
	end

	for i, style in ipairs(t) do
		local start = style[1]
		local length = style[2]
		local rr = style[3]
		local gg = style[4]
		local bb = style[5]
		local scope = style[6]

		if not override_colorscheme then
			local hl = nil
			for j, map in ipairs(scope_hl_map) do
				if string.find(scope, map[1]) then
					hl = map[2]
				end
			end
			if custom_scope_map then
				for j, map in ipairs(custom_scope_map) do
					if string.find(scope, map[1]) then
						hl = map[2]
					end
				end
			end
			if hl then
				api.nvim_buf_add_highlight(b, 0, hl, n - 1, start, start + length)
			end
		else
			local clr = string.format("%02x%02x%02x", rr, gg, bb)
			if clr and clr:len() < 8 then
				api.nvim_set_hl(0, clr, { fg = "#" .. clr })
				api.nvim_buf_add_highlight(b, 0, clr, n - 1, start, start + length)
			end
		end
	end
end

local function txmt_highlight_buffer(buffer)
	if not enabled then
		return
	end

	if not txmt_set_language(buffer) then
		return
	end

	local b = buffer
	if not b then
		b = api.nvim_get_current_buf()
	end

	local lc = api.nvim_buf_line_count(b)
	local sr = 50 -- screen rows

	local r, c = unpack(vim.api.nvim_win_get_cursor(0))
	local ls = r - sr
	local le = r + sr

	if ls < 0 then
		ls = 0
	end
	if le > lc then
		le = lc
	end

	for i = ls, le - 1, 1 do
		if module.highlight_is_line_dirty(i + 1, b) ~= 0 then
			local lines = api.nvim_buf_get_lines(b, i, i + 1, false)
			txmt_highlight_line(i + 1, lines[1])
		end
	end
end

_txmt_highlight_buffer = txmt_highlight_buffer

local function txmt_deferred_highlight_current_buffer(timeout)
	if not enabled then
		return
	end

	if render_timer then
		render_timer:close()
	end

	if timeout == nil then
		timeout = hl_default_timeout
	end

	render_timer = vim.defer_fn(function()
		render_timer = nil
		txmt_highlight_buffer()
	end, timeout)
end

local function txmt_on_buf_enter()
	if not enabled then
		return
	end

	if quick_load then
		txmt_deferred_highlight_current_buffer(hl_timeout_next_tick)
	else
		txmt_highlight_buffer()
	end
end

local function txmt_on_buf_delete()
	local b = api.nvim_get_current_buf()
	txmt_free_buffer(b)
end

local function txmt_on_cursor_moved()
	if not enabled then
		return
	end

	txmt_highlight_buffer()

	if debug_scopes then
		local b = api.nvim_get_current_buf()
		if not buffer_data[b] then
			return
		end
		local r, c = unpack(vim.api.nvim_win_get_cursor(0))
		local scopes = buffer_data[b]["scopes"]
		if scopes then
			local t = scopes[r]
			if t then
				for i, style in ipairs(t) do
					local start = style[1]
					local length = style[2]
					local scope = style[6]
					if c >= start and c < start + length then
						print(scope)
					end
				end
			end
		end
	end

	-- txmt_deferred_highlight_current_buffer()
end

local function txmt_on_text_changed_i()
	if not enabled then
		return
	end

	local b = api.nvim_get_current_buf()
	local r, c = unpack(vim.api.nvim_win_get_cursor(0))
	local i = r - 1
	local lines = api.nvim_buf_get_lines(b, i, i + 1, false)

	local lc = api.nvim_buf_line_count(b)
	local diff = 0
	local changed_lines = 1
	if buffer_data[b] then
		if buffer_data[b]["langid"] == -1 then
			return
		end
		local last = buffer_data[b]["last_count"]
		buffer_data[b]["last_count"] = lc
		if last then
			diff = lc - last
			if diff > 0 then
				changed_lines = diff
				for nr = 0, diff, 1 do
					module.highlight_add_block(nr)
				end
			end
			if diff < 0 then
				changed_lines = -diff
				for nr = 0, -diff, 1 do
					module.highlight_remove_block(nr)
				end
			end
		end
	end

	for cl = 0, changed_lines, 1 do
		module.highlight_make_line_dirty(i + cl, b)
	end

	txmt_highlight_line(i + 1, lines[1])
	txmt_deferred_highlight_current_buffer(hl_timeout_after_change)
end

local function txmt_on_text_changed()
	if changed_timer then
		changed_timer:close()
	end

	changed_timer = vim.defer_fn(function()
		changed_timer = nil
		txmt_on_text_changed_i()
	end, 150)
end

local function txmt_enable()
	if not enabled then
		enabled = true
		txmt_highlight_buffer()
	end
end

local function txmt_disable()
	if enabled then
		enabled = false
		override_colorscheme = false

		for b, v in pairs(buffer_data) do
			txmt_free_buffer(b)
		end

		vim.cmd("colorscheme " .. vim.g.colors_name)
	end
end

local function txmt_toggle()
	if enabled then
		txmt_disable()
	else
		txmt_enable()
	end
end

local themes = nil
local themes_map = {}
local function txmt_on_set_themes_complete(opts)
	if not themes then
		themes = module.highlight_themes()
	end

	local l = {}
	for i, theme in ipairs(themes) do
		l[i] = theme[1]
		themes_map[theme[1]] = theme
	end

	if not l then
		return { "Monokai" }
	end

	return l
end

local function txmt_select_theme(opts)
	override_colorscheme = true
	theme_name = opts.args
	loaded_theme = nil

	load_theme()

	txmt_deferred_highlight_current_buffer()
end

local languages = nil
local languages_map = {}
local function txmt_on_set_languages_complete()
	if not languages then
		languages = module.highlight_languages()
	end

	local l = {}
	for i, lang in ipairs(languages) do
		l[i] = lang[1]
		languages_map[lang[1]] = lang
	end

	return l
end

local function txmt_select_language(opts)
	local b = api.nvim_get_current_buf()

	txmt_free_buffer(b)
	buffer_data[b] = {
		extension = languages_map[opts.args][3],
	}

	txmt_highlight_buffer()
end

local function txmt_info()
	local b = api.nvim_get_current_buf()
	if buffer_data[b] then
		vim.pretty_print(buffer_data[b])
	end
end

local function txmt_debug_scopes()
	debug_scopes = not debug_scopes
	if debug_scopes then
		txmt_disable()
		txmt_enable()
	end
end

api.nvim_create_autocmd("BufEnter", { group = group, callback = txmt_on_buf_enter })
api.nvim_create_autocmd("BufDelete", { group = group, callback = txmt_on_buf_delete })
api.nvim_create_autocmd("TextChangedI", { group = group, callback = txmt_on_text_changed_i })
api.nvim_create_autocmd("TextChanged", { group = group, callback = txmt_on_text_changed })
api.nvim_create_autocmd("CursorMoved", { group = group, callback = txmt_on_cursor_moved })
api.nvim_create_autocmd("CursorMovedI", { group = group, callback = txmt_on_cursor_moved })

api.nvim_create_user_command("TxMtToggle", txmt_toggle, { bang = true, desc = "toggle textmate syntax highlighter" })
api.nvim_create_user_command("TxMtEnable", txmt_enable, { bang = true, desc = "enable textmate syntax highlighter" })
api.nvim_create_user_command("TxMtDisable", txmt_disable, { bang = true, desc = "disable textmate syntax highlighter" })
api.nvim_create_user_command(
	"TxMtTheme",
	txmt_select_theme,
	{ bang = true, nargs = 1, desc = "set textmate theme", complete = txmt_on_set_themes_complete }
)
api.nvim_create_user_command(
	"TxMtLanguage",
	txmt_select_language,
	{ bang = true, nargs = 1, desc = "set textmate theme", complete = txmt_on_set_languages_complete }
)
api.nvim_create_user_command("TxMtDebugScopes", txmt_debug_scopes, { bang = true, desc = "debug textmate scopes" })
api.nvim_create_user_command("TxMtInfo", txmt_info, { bang = true, desc = "textmate info" })

txmt_initialize()

return {
	setup = setup,
}
