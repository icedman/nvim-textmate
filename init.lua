-- hack?
local info = debug.getinfo(1,'S')
local cpath = package.cpath

package.cpath = package.cpath .. ';' .. info.source:gsub('init.lua', 'build/textmate.so'):gsub('@', '')

local ok, module = pcall(require, 'textmate')
if not ok then
  -- not loaded
end
-- local module = require('textmate')
package.cpath = cpath

local api = vim.api

local function setup(parameters)
end

function highlight_line(n, l)
    api.nvim_buf_clear_namespace(api.nvim_get_current_buf(), 0, n-1, -1)

    -- local src = api.new_highlight_source()

    local t = module.highlight_line(l)
    for i, style in ipairs(t) do
        -- print(style)
        local start = style[1]
        local length = style[2]
        local r = style[3]
        local g = style[4]
        local b = style[5]
        local clr = string.format("%x%x%x", r,g,b)
        -- print(clr)
        api.nvim_set_hl(0, clr, { fg = '#' .. clr })
        api.nvim_buf_add_highlight(api.nvim_get_current_buf(), 0, clr, n-1, start, start + length)
    end
end

return {
    setup = setup
}
