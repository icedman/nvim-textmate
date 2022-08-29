# nvim-textmate
A textmate-based syntax highlighter to nvim, compatible with VScode themes and grammars

![Screen Shot](https://raw.githubusercontent.com/icedman/nvim-textmate/main/screenshots/Screenshot%20from%202022-08-18%2010-15-03.png)

# install

```sh
git clone http://github.com/icedman/nvim-textmate
cd nvim-textmate
make
```

# packer.nvim

```lua
use "icedman/nvim-textmate"
```

# setup

```lua
-- init.lua
require('nvim-textmate')
```

<br/>
<br/>or with setup options<br/>


```lua
require('nvim-textmate').setup({
    quick_load = true,
    theme_name = 'Dracula',
    override_colorscheme = false
})
```

## setup options

* quick_load - defers loading of grammar and theme at the opening of a buffer 
* theme_name - select a textmate format or vscode compatible theme
* override_colorscheme - apply colorscheme from textmate theme
* custom_scope_map - add more scope to namespace mapping (see colormap.lua)
* extension_paths - set vscode extension search path
* debug_scopes - print scope name under cursor

# extensions

Copy vscode theme and grammar extensions to any of these directories:

```sh
~/.config/nvim/lua/nvim-textmate/
~/.editor/extensions/
~/.vscode/extensions/
```

# commands

* TxMtEnable
* TxMtDisable
* TxMtToggle
* TxMtTheme
* TxMtDebugScopes

# known issues

* a colorscheme must be loaded prior to running nvim-textmate
* cpp - Some grammars take a bit of time to load. cpp, the largest grammar file causes a visible lag on first load; hence the *quick_load* option is available.
* markdown - Other grammars - like markdown will load other grammar languages for inline code and will re-render after the other languages are loaded.
* scrolling and text editing - syntax highlighting is currently done at these events as a debounced (defer_fn) function.

# warning

* This plugin is just a proof of concept - from a novice lua coder, and much worse - from a non neovim user (not yet at least)

