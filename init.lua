-- hack?
local info = debug.getinfo(1,'S')
local cpath = package.cpath

package.cpath = package.cpath ..
    ';' .. info.source:gsub('init.lua', 'build/textmate.so'):gsub('@', '') ..
    ';' .. info.source:gsub('init.lua', '_build/textmate.so'):gsub('@', '') ..
    ';' .. info.source:gsub('init.lua', 'textmate.so'):gsub('@', '')

local ok, module = pcall(require, 'textmate')
if not ok then
  -- not loaded
end
-- local module = require('textmate')
package.cpath = cpath

local api = vim.api
local buffer_data = {}

local function setup(parameters)
end

function txmt_set_language()
    local b = api.nvim_get_current_buf()
    if buffer_data[b] == nil then
        buffer_data[b] = {}
    end

    local filetype = vim.bo.filetype
    buffer_data[b]['filetype'] = filetype

    if buffer_data[b]['langid'] == nil then
        local langid = module.highlight_load_language(vim.fn.expand('%'))
        buffer_data[b]['langid'] = langid
    end

    -- print(buffer_data[b]['langid'])
    return true
end

function txmt_text_changed_i()
    local b = api.nvim_get_current_buf()
    local r,c = unpack(vim.api.nvim_win_get_cursor(0))
    local i = r - 1
    local lines = api.nvim_buf_get_lines(b, i, i+1, false)
    txmt_highlight_current_line(i+1, lines[1])
end

function txmt_highlight_enable()
    local homedir = vim.fn.expand('~')
    module.highlight_set_extensions_dir(homedir .. '/.editor/extensions/')
    module.highlight_set_extensions_dir(homedir .. '/.vscode/extensions/')
    module.highlight_set_extensions_dir(info.source:gsub('init.lua', 'extensions/'))
    module.highlight_load_theme('Dracula')

    local group = api.nvim_create_augroup("textmate", { clear = true })
    -- api.nvim_create_autocmd("BufEnter", { group = group, callback = txmt_highlight_current_buffer })
    api.nvim_create_autocmd("TextChangedI", { group = group, callback = txmt_text_changed_i })
    txmt_highlight_current_buffer()
    -- highlight all open buffers
end

function txmt_highlight_current_buffer()
    if txmt_set_language() ~= true then
        return
    end

    local b = api.nvim_get_current_buf()
    local lc = api.nvim_buf_line_count(b)
    for i = 0,lc-1,1
    do
        local lines = api.nvim_buf_get_lines(b, i, i+1, false)
        txmt_highlight_current_line(i+1, lines[1])
    end
end

function txmt_highlight_current_line(n, l)
    local b = api.nvim_get_current_buf()
    if txmt_set_language() ~= true then
        return
    end

    api.nvim_buf_clear_namespace(b, 0, n-1, n)
    local langid = buffer_data[b]['langid']
    local t = module.highlight_line(l, n, langid)
    for i, style in ipairs(t) do
        local start = style[1]
        local length = style[2]
        local rr = style[3]
        local gg = style[4]
        local bb = style[5]
        local clr = string.format("%x%x%x", rr,gg,bb)
        api.nvim_set_hl(0, clr, { fg = '#' .. clr })
        api.nvim_buf_add_highlight(b, 0, clr, n-1, start, start + length)
    end
end

return {
    setup = setup
}
