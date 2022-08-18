local info = debug.getinfo(1, "S")
local cpath = package.cpath

package.cpath = package.cpath
	.. ";"
	.. info.source:gsub("init.lua", "build/textmate.so"):gsub("@", "")
	.. ";"
	.. info.source:gsub("init.lua", "_build/textmate.so"):gsub("@", "")
	.. ";"
	.. info.source:gsub("init.lua", "textmate.so"):gsub("@", "")

-- local module = require('textmate')

local ok, module = pcall(require, "textmate")

package.cpath = cpath

if not ok then
	-- probably need to run cmake && make
	return
end

local api = vim.api
local render_timer = nil
local changed_timer = nil
local buffer_data = {}

local hl_default_timeout = 50
local hl_timeout_next_tick = 0
local hl_timeout_after_change = 150
local hl_timeout_after_language_load = 1500

local group = api.nvim_create_augroup("textmate", { clear = true })
local enabled = true
local initialized = false
local quick_load

local _txmt_highlight_current_buffer

local function setup(parameters)
	quick_load = parameters['quick_load']
end

local function txmt_highlight_initialize()
	local homedir = vim.fn.expand("~")
	module.highlight_set_extensions_dir(homedir .. "/.editor/extensions/")
	module.highlight_set_extensions_dir(homedir .. "/.vscode/extensions/")
	module.highlight_set_extensions_dir(info.source:gsub("init.lua", "extensions/"):gsub("@", ""))
	module.highlight_load_theme("Dracula")
	initialized = true
end

local function txmt_set_language()
	if enabled ~= true then
		return false
	end
	if initialized ~= true then
		txmt_highlight_initialize()
	end

	local b = api.nvim_get_current_buf()
	if not buffer_data[b] then
		buffer_data[b] = {}
	end

	local filetype = vim.bo.filetype
	buffer_data[b]["filetype"] = filetype

	-- should exclude?

	if not buffer_data[b]["langid"] then
		local langid = module.highlight_load_language(vim.fn.expand("%"))
		buffer_data[b]["langid"] = langid
		vim.defer_fn(function()
			_txmt_highlight_current_buffer()
		end, hl_timeout_after_language_load)
	end

	if buffer_data[b]["langid"] == -1 then
		return false
	end

	module.highlight_set_language(buffer_data[b]["langid"])
	return true
end

local function txmt_highlight_current_line(n, l)
	if txmt_set_language() ~= true then
		return
	end

	local b = api.nvim_get_current_buf()

	-- if module.highlight_is_line_dirty(n, b) == 0 then
	-- 	return
	-- end

	api.nvim_buf_clear_namespace(b, 0, n - 1, n)
	local langid = buffer_data[b]["langid"]
	if langid == -1 then
		return
	end
	local t = module.highlight_line(l, n, langid, b)
	for i, style in ipairs(t) do
		local start = style[1]
		local length = style[2]
		local rr = style[3]
		local gg = style[4]
		local bb = style[5]
		local clr = string.format("%02x%02x%02x", rr, gg, bb)
		api.nvim_set_hl(0, clr, { fg = "#" .. clr })
		api.nvim_buf_add_highlight(b, 0, clr, n - 1, start, start + length)
	end
end

local function txmt_highlight_current_buffer()
	if txmt_set_language() ~= true then
		return
	end

	local b = api.nvim_get_current_buf()
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
			txmt_highlight_current_line(i + 1, lines[1])
		end
	end
end

_txmt_highlight_current_buffer = txmt_highlight_current_buffer

local function txmt_deferred_highlight_current_buffer(timeout)
	if render_timer ~= nil then
		render_timer:close()
	end

	if timeout == nil then
		timeout = hl_default_timeout
	end

	render_timer = vim.defer_fn(function()
		render_timer = nil
		txmt_highlight_current_buffer()
	end, timeout)
end

local function txmt_on_buf_enter()
	-- local b = api.nvim_get_current_buf()
	-- local lc = api.nvim_buf_line_count(b)
	if quick_load then
		txmt_deferred_highlight_current_buffer(hl_timeout_next_tick)
	else
		txmt_highlight_current_buffer()
	end
end

local function txmt_on_buf_delete()
	-- delete doc at module.cpp
	-- delete doc at docs
	-- print('delete' .. api.nvim_get_current_buf())
end

local function txmt_on_cursor_moved()
	txmt_deferred_highlight_current_buffer()
end

local function txmt_on_text_changed_i()
	local b = api.nvim_get_current_buf()
	local r, c = unpack(vim.api.nvim_win_get_cursor(0))
	local i = r - 1
	local lines = api.nvim_buf_get_lines(b, i, i + 1, false)

	local lc = api.nvim_buf_line_count(b)
	local diff = 0
	local changed_lines = 1
	if buffer_data[b] ~= nil then
		local last = buffer_data[b]["last_count"]
		buffer_data[b]["last_count"] = lc
		if last ~= nil then
			diff = lc - last
			if diff > 0 then
				changed_lines = diff
				for nr = 0, diff, 1 do
					module.highlight_add_block(nr - 1)
				end
			end
			if diff < 0 then
				changed_lines = -diff
				for nr = 0, -diff, 1 do
					module.highlight_remove_block(nr - 1)
				end
			end
		end
	end

	for cl = 0, changed_lines, 1 do
		module.highlight_make_line_dirty(i + cl, b)
	end

	txmt_highlight_current_line(i + 1, lines[1])
	txmt_deferred_highlight_current_buffer(hl_timeout_after_change)
end

local function txmt_on_text_changed()
	-- txmt_on_text_changed_i()
	if changed_timer ~= nil then
		changed_timer:close()
	end

	changed_timer = vim.defer_fn(function()
		changed_timer = nil
		txmt_on_text_changed_i()
	end, 150)
end

api.nvim_create_autocmd("BufEnter", { group = group, callback = txmt_on_buf_enter })
api.nvim_create_autocmd("BufDelete", { group = group, callback = txmt_on_buf_delete })
api.nvim_create_autocmd("TextChangedI", { group = group, callback = txmt_on_text_changed_i })
api.nvim_create_autocmd("TextChanged", { group = group, callback = txmt_on_text_changed })
api.nvim_create_autocmd("CursorMoved", { group = group, callback = txmt_on_cursor_moved })

local function txmt_toggle()
	if enabled then
		enabled = false
	else
		enabled = true
	end
end

api.nvim_create_user_command(
	"TextMateToggle",
	txmt_toggle,
	{ bang = true, desc = "toggle textmate syntax highlighter" }
)

local function txmt_set_theme(opts)
	module.highlight_load_theme(opts.args)
	-- all buffers
	txmt_deferred_highlight_current_buffer()
end

local themes = nil
local function txmt_on_set_theme_complete()
	if not themes then
		themes = module.highlight_themes()
	end

	local l = {}
	for i, theme in ipairs(themes) do
		l[i] = theme[1]
	end

	if not l then
		return { "Monokai" }
	end

	return l
end

api.nvim_create_user_command("TextMateTheme", txmt_set_theme, {
	bang = true,
	nargs = 1,
	desc = "set textmate theme",
	complete = txmt_on_set_theme_complete,
})

return {
	setup = setup,
}
