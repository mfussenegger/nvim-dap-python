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

Supported test frameworks are `unittest` and `pytest`. It defaults to using
`unittest`. To configure `pytest` set the test runner like this:


```vimL
lua require('dap-python').test_runner = 'pytest'
```


## Mappings


```vimL
nnoremap <silent> <leader>dn :lua require('dap-python').test_method()<CR>
nnoremap <silent> <leader>df :lua require('dap-python').test_class()<CR>
vnoremap <silent> <leader>ds <ESC>:lua require('dap-python').debug_selection()<CR>
```


## Looking for Maintainers

I'm looking for co-maintainers who are:

- Ensuring test runners like `pytest` are supported as well.
- Ensuring Windows is well supported


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
