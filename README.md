# nvim-dap-python

An extension for [nvim-dap][1] providing default configurations for python and methods to debug individual test methods or classes.


## Installation

- Requires Neovim >= 0.5
- Requires [nvim-dap][1]
- Requires [debugpy][3]
- Install like any other neovim plugin:
  - If using [vim-plug][6]: `Plug 'mfussenegger/nvim-dap-python'`
  - If using [packer.nvim][7]: `use 'mfussenegger/nvim-dap-python'`

If you want to use the test runner functionality, it additionally requires a
tree sitter parser for Python.


### Debugpy

It is recommended to install debugpy into a dedicated virtualenv. To do so:

```bash
mkdir .virtualenvs
cd .virtualenvs
python -m venv debugpy
debugpy/bin/python -m pip install debugpy
```

The debugger will automatically pick-up another virtual environment if it is
activated before neovim is started.


### Tree-sitter

Install either:

- Via `:TSInstall python` of [nvim-treesitter][4]
- Compile the parser from [tree-sitter-python][5] and copy it into `.config/nvim/parser/`:
  - `git clone https://github.com/tree-sitter/tree-sitter-python.git`
  - `cd tree-sitter-python`
  - `cc -O2 -o ~/.config/nvim/parser/python}.so -I./src src/parser.c src/scanner.cc -shared -Os -lstdc++ -fPIC`


## Usage

1. Call `setup` in your `init.vim` to register the adapter and configurations:

```vimL
lua require('dap-python').setup('~/.virtualenvs/debugpy/bin/python')
```

The argument to `setup` is the path to the python installation which contains the `debugpy` module.


2. Use nvim-dap as usual.

- Call `:lua require('dap').continue()` to start debugging.
- See `:help dap-mappings` and `:help dap-api`.
- Use `:lua require('dap-python').test_method()` to debug the closest method above the cursor.

Supported test frameworks are `unittest`, `pytest` and `django`. It defaults to using
`unittest`.

To configure a different runner, change the `test_runner` variable. For example
to configure `pytest` set the test runner like this in `vimL`:


```vimL
lua require('dap-python').test_runner = 'pytest'
```

You can also add custom runners. An example in `Lua`:

```lua
local test_runners = require('dap-python').test_runners

-- `test_runners` is a table. The keys are the runner names like `unittest` or `pytest`.
-- The value is a function that takes three arguments:
-- The classname, a methodname and the opts
-- (The `opts` are coming passed through from either `test_method` or `test_class`)
-- The function must return a module name and the arguments passed to the module as list.
test_runners.your_runner = function(classname, methodname, opts)
  local args = {classname, methodname}
  return 'modulename', args
end
```


### Documentation

See `:help dap-python`


## Mappings


```vimL
nnoremap <silent> <leader>dn :lua require('dap-python').test_method()<CR>
nnoremap <silent> <leader>df :lua require('dap-python').test_class()<CR>
vnoremap <silent> <leader>ds <ESC>:lua require('dap-python').debug_selection()<CR>
```


## Custom configuration

If you call the `require('dap-python').setup` method it will create a few `nvim-dap` configuration entries. These configurations are general purpose configurations suitable for many use cases, but you may need to customize the configurations - for example if you want to use Docker containers.

To add your own entries, you can extend the `dap.configurations.python` list after calling the `setup` function:

```vimL
lua << EOF
require('dap-python').setup('/path/to/python')
table.insert(require('dap').configurations.python, {
  type = 'python',
  request = 'launch',
  name = 'My custom launch configuration',
  program = '${file}',
  -- ... more options, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings
})
EOF
```

An alternative is to use project specific `.vscode/launch.json` files, see `:help dap-launch.json`.


The [Debugpy Wiki][debugpy_wiki] contains a list of all supported configuration options.


## Alternatives

### [vim-ultest](https://github.com/rcarriga/vim-ultest)

A test runner building upon vim-test with nvim-dap support.
Aims to work for all python runners.


[1]: https://github.com/mfussenegger/nvim-dap
[3]: https://github.com/microsoft/debugpy
[4]: https://github.com/nvim-treesitter/nvim-treesitter
[5]: https://github.com/tree-sitter/tree-sitter-python
[6]: https://github.com/junegunn/vim-plug
[7]: https://github.com/wbthomason/packer.nvim
[debugpy_wiki]: https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings
