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

  it('Support multiprocessing extension', function()
    local program = vim.fn.expand('%:p:h') .. '/tests/example.py'
    local config = {
      type = 'python',
      request = 'launch',
      name = 'Launch file',
      subProcess = true,
      program = program,
    }

    local win = api.nvim_get_current_win()
    local bufnr = vim.fn.bufadd(program)
    api.nvim_win_set_buf(win, bufnr)
    api.nvim_win_set_cursor(win, { 17, 0 })

    dap.set_log_level('TRACE')
    dap.toggle_breakpoint()

    local debugpyAttach_calls = 0
    dap.listeners.after['event_debugpyAttach']['dap-python-test'] = function()
      debugpyAttach_calls = debugpyAttach_calls + 1
    end
    local sessions = {}
    dap.listeners.after.event_initialized['dap-python-test'] = function(session)
      table.insert(sessions, session)
    end

    dap.run(config)
    vim.wait(1000, function()
      local session = dap.session()
      return (session
        and session.initialized
        and debugpyAttach_calls == 2
        and #sessions == 3
      )
    end)
    assert.are.same(3, #sessions) -- root session and two children
    assert.are.same(2, debugpyAttach_calls)
  end)
end)

vim.fn.delete(venv_dir, 'rf')
