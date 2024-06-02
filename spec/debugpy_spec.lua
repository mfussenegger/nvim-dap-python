local venv_dir = os.tmpname()
local dap = require('dap')
local dappy = require('dap-python')
local api = vim.api

describe('dap with debugpy', function()
  os.remove(venv_dir)
  os.execute('python -m venv "' .. venv_dir .. '"')
  os.execute(venv_dir .. '/bin/python -m pip install debugpy')
  dappy.setup(venv_dir .. '/bin/python')

  after_each(function()
    dap.terminate()
    require('dap.breakpoints').clear()
  end)

  it('Can start session and break at breakpoint', function()
    local program = vim.fn.expand('%:p:h') .. '/spec/simple.py'
    local config = {
      type = 'python',
      request = 'launch',
      name = 'Launch file',
      subProcess = false,
      program = program,
    }
    local win = api.nvim_get_current_win()
    local bufnr = vim.fn.bufadd(program)
    api.nvim_win_set_buf(win, bufnr)
    api.nvim_win_set_cursor(win, { 8, 0 })
    dap.toggle_breakpoint()
    dap.run(config)
    vim.wait(1000, function()
      local session = dap.session()
      return (session and session.initialized or false)
    end)
    assert.are_not.same(nil, dap.session())
  end)
end)

vim.fn.delete(venv_dir, 'rf')
