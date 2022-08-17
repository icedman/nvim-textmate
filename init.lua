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
local render_timer = nil
local buffer_data = {}

local group = api.nvim_create_augroup("textmate", { clear = true })
local enabled = false

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

    module.highlight_set_language(buffer_data[b]['langid'])
    -- print(buffer_data[b]['langid'])
    return true
end

function txmt_on_text_changed_i()
    local b = api.nvim_get_current_buf()
    local r,c = unpack(vim.api.nvim_win_get_cursor(0))
    local i = r - 1
    local lines = api.nvim_buf_get_lines(b, i, i+1, false)
    txmt_highlight_current_line(i+1, lines[1])
    -- txmt_deferred_highlight_current_buffer()
end

function txmt_highlight_enable()
    local homedir = vim.fn.expand('~')
    module.highlight_set_extensions_dir(homedir .. '/.editor/extensions/')
    module.highlight_set_extensions_dir(homedir .. '/.vscode/extensions/')
    module.highlight_set_extensions_dir(info.source:gsub('init.lua', 'extensions/'))
    module.highlight_load_theme('Dracula')

    -- txmt_deferred_highlight_current_buffer(2500)
    -- highlight all open buffers

    enabled = true
end

function txmt_highlight_current_buffer()
    if txmt_set_language() ~= true then
        return
    end

    local b = api.nvim_get_current_buf()
    local lc = api.nvim_buf_line_count(b)
    local sr = 40 -- screen rows/2
    
    local r,c = unpack(vim.api.nvim_win_get_cursor(0))
    local ls = r - sr
    local le = r + sr

    if ls < 0 then
        ls = 0
    end
    if le > lc then
        le = lc
    end

    -- print(r .. ': ' .. ls .. ' - ' .. le)

    for i = ls, le-1, 1
    do
        local lines = api.nvim_buf_get_lines(b, i, i+1, false)
        txmt_highlight_current_line(i+1, lines[1])
    end
end

function txmt_deferred_highlight_current_buffer(timeout)
    if render_timer ~= nil then
        render_timer:close()
    end

    if timeout == nil then
        timeout =50
    end

    render_timer = vim.defer_fn(
        function()
            render_timer = nil
            txmt_highlight_current_buffer()
        end,
        timeout
    )
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

function txmt_on_buf_enter(args) 
    txmt_deferred_highlight_current_buffer(250)
end

function txmt_on_cursor_moved(args)
    txmt_deferred_highlight_current_buffer()
end

txmt_highlight_enable()
api.nvim_create_autocmd("BufEnter", { group = group, callback = txmt_on_buf_enter })
api.nvim_create_autocmd("TextChangedI", { group = group, callback = txmt_on_text_changed_i })
api.nvim_create_autocmd("CursorMoved", { group = group, callback = txmt_on_cursor_moved })

return {
    setup = setup
}
