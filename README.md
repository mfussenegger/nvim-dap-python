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

Options to install [debugpy][3]:

1. Via a system package manager. For example:

```bash
pacman -S python-debugpy
```

2. Via `pip` in a `venv`:

```bash
mkdir ~/.virtualenvs
cd ~/.virtualenvs
python -m venv debugpy
debugpy/bin/python -m pip install debugpy
```

Note that the virutalenv used for the `debugpy` can be independent from any
virtualenv you're using in your projects.

`nvim-dap-python` tries to detect your project `venv` and should recognize any
dependencies your project has. See [Python dependencies and
virtualenv](#python-dependencies-and-virtualenv)


3. Implicit via [uv][uv]

See [Usage](#usage): You need to use `require("dap-python").setup("uv")`


### Tree-sitter

To install the python tree-sitter parser you can either:

- Use `:TSInstall python` from [nvim-treesitter][4]
- Compile the parser from [tree-sitter-python][5] and copy it into `.config/nvim/parser/`:
  - `git clone https://github.com/tree-sitter/tree-sitter-python.git`
  - `cd tree-sitter-python`
  - `cc -O2 -o ~/.config/nvim/parser/python}.so -I./src src/parser.c src/scanner.cc -shared -Os -lstdc++ -fPIC`


## Usage

1. Call `setup` in your `init.lua` to register the adapter and configurations.

   If installed in a virtual environment:

   ```lua
   require("dap-python").setup("/path/to/venv/bin/python")
   -- If using the above, then `/path/to/venv/bin/python -m debugpy --version`
   -- must work in the shell
   ```

   If installed globally:

   ```lua
   require("dap-python").setup("python3")
   -- If using the above, then `python3 -m debugpy --version`
   -- must work in the shell
   ```

   If using [uv][uv]:

   ```lua
   require("dap-python").setup("uv")
   ```


2. Use `nvim-dap` as usual.

   - Call `:lua require('dap').continue()` to start debugging.
   - See `:help dap-mappings` and `:help dap-api`.
   - Use `:lua require('dap-python').test_method()` to debug the closest method above the cursor.

   Supported test frameworks are `unittest`, `pytest` and `django`. By default it
   tries to detect the runner by probing for presence of `pytest.ini` or
   `manage.py`, or for a `tool.pytest` directive inside `pyproject.toml`, if
   none are present it defaults to `unittest`.

   To configure a different runner, change the `test_runner` variable. For
   example, to configure `pytest` set the test runner like this in your
   `init.lua`:

   ```lua
   require('dap-python').test_runner = 'pytest'
   ```

   You can also add custom runners. An example in `Lua`:

   ```lua
   local test_runners = require('dap-python').test_runners

   -- `test_runners` is a table. The keys are the runner names like `unittest` or `pytest`.
   -- The value is a function that takes two arguments:
   -- The classnames and a methodname
   -- The function must return a module name and the arguments passed to the module as list.

   ---@param classnames string[]
   ---@param methodname string?
   test_runners.your_runner = function(classnames, methodname)
     local path = table.concat({
        table.concat(classnames, ":"),
        methodname,
     }, "::")
     return 'modulename', {"-s", path}
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

If you call the `require('dap-python').setup` method it will create a few
`nvim-dap` configuration entries. These configurations are general purpose
configurations suitable for many use cases, but you may need to customize the
configurations - for example if you want to use Docker containers.

To add your own entries you can create per project `.vscode/launch.json`
configuration files. See `:help dap-launch.json`.

Or you can add your own global entries by extending the
`dap.configurations.python` list after calling the `setup` function:

```lua
require('dap-python').setup('/path/to/python')
table.insert(require('dap').configurations.python, {
  type = 'python',
  request = 'launch',
  name = 'My custom launch configuration',
  program = '${file}',
  -- ... more options, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings
})
```

The [Debugpy Wiki][debugpy_wiki] contains a list of all supported configuration options.


## Python dependencies and virtualenv

`nvim-dap-python` by default tries to detect a virtual environment and uses it
when debugging your application. It looks for:

- The environment variables `VIRTUAL_ENV` and `CONDA_PREFIX`
- The folders `venv`, `.venv`, `env`, `.env` relative to either the current
  working directory or the `root_dir` of a active language server client. See
  `:h lsp.txt` for more information about the latter.

If you're using another way to manage virtual environments, you can set a
custom `resolve_python` function:

```lua
require('dap-python').resolve_python = function()
  return '/absolute/path/to/python'
end
```

Or explicitly set the `pythonPath` property within your debugpy/nvim-dap
configurations. See `:h dap-configuration` and [Launch/Attach
Settings][debugpy_wiki]


## Alternatives

### [vim-ultest](https://github.com/rcarriga/vim-ultest)

A test runner building upon vim-test with nvim-dap support.
Aims to work for all python runners.

## Development

- Generate docs using [vimcats][vimcats]:

```bash
vimcats -f -t lua/dap-python.lua > doc/dap-python.txt
```


[1]: https://github.com/mfussenegger/nvim-dap
[3]: https://github.com/microsoft/debugpy
[4]: https://github.com/nvim-treesitter/nvim-treesitter
[5]: https://github.com/tree-sitter/tree-sitter-python
[6]: https://github.com/junegunn/vim-plug
[7]: https://github.com/wbthomason/packer.nvim
[debugpy_wiki]: https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings
[vimcats]: https://github.com/mrcjkb/vimcats
[uv]: https://docs.astral.sh/uv/
