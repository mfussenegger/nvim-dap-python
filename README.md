# nvim-dap-python

An extension for [nvim-dap][1] providing default configurations for python and methods to debug individual test methods or classes.


## Installation


- Requires [Neovim HEAD/nightly][2]
- Requires [nvim-dap][1]
- Requires [debugpy][3]
- Requires a tree sitter parser for python. Install either via `:TSInstall python` of [nvim-treesitter][4] or manually compile the parser from [tree-sitter-python][5] and copy it into `.config/nvim/parser/`.
- Install like any other neovim plugin


It is recommended to install debugpy into a dedicated virtualenv. To do so:

```bash
mkdir .virtualenvs
cd .virtualenvs
python -m venv debugpy
debugpy/bin/python -m pip install debugpy
```


## Usage

1. Call `setup` in your `init.vim` to register the adapter and configurations:

```vimL
lua require('dap-python').setup('~/.virtualenvs/debugpy/bin/python')
```

The argument to `setup` is the path to the python installation which contains the `debugpy` module.


2. Use nvim-dap as usual.

- Call `:lua require('dap').continue()` to start debugging.
- See `:help dap-mappings` and `:help dap-api`.
- Use `:lua require('dap-python').test_method` to debug the closest method above the cursor.

Currently this only works with the `unittest` test framework. `pytest` and others are not supported yet.


## Work in progress


- Use `:lua require('dap-python').test_class` to debug the closest class above the cursor.


## Looking for Maintainers

I'm looking for co-maintainers who are:

- Ensuring test runners like `pytest` are supported as well.
- Ensuring Windows is well supported


[1]: https://github.com/mfussenegger/nvim-dap
[2]: https://github.com/neovim/neovim/releases/tag/nightly
[3]: https://github.com/microsoft/debugpy
[4]: https://github.com/nvim-treesitter/nvim-treesitter
[5]: https://github.com/tree-sitter/tree-sitter-python
