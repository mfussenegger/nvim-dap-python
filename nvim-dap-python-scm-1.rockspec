local _MODREV, _SPECREV = 'scm', '-1'
rockspec_format = "3.0"
package = 'nvim-dap-python'
version = _MODREV .. _SPECREV

description = {
  summary = 'Python extension for nvim-dap',
  labels = {
    'neovim',
    'plugin',
    'debug-adapter-protocol',
    'debugger',
    'python',
  },
  homepage = 'https://github.com/mfussenegger/nvim-dap-python',
  license = 'GPL-3.0',
}

dependencies = {
  'lua >= 5.1, < 5.4',
  'nvim-dap',
}

test_dependencies = {
  "nlua",
  "tree-sitter-python"
}

source = {
   url = 'git://github.com/mfussenegger/nvim-dap-python',
}

build = {
   type = 'builtin',
   copy_directories = {
     'doc',
     'plugin',
   },
}
