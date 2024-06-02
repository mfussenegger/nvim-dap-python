---@mod dap-python Python extension for nvim-dap

local api = vim.api
local M = {}
local uv = vim.uv or vim.loop

--- Test runner to use by default.
--- The default value is dynamic and depends on `pytest.ini` or `manage.py` markers.
--- If neither is found "unittest" is used. See |dap-python.test_runners|
--- Override this to set a different runner:
--- ```
--- require('dap-python').test_runner = "pytest"
--- ```
---@type (string|fun():string) name of the test runner
M.test_runner = nil


--- Function to resolve path to python to use for program or test execution.
--- By default the `VIRTUAL_ENV` and `CONDA_PREFIX` environment variables are
--- used if present.
---@type nil|fun():nil|string name of the test runner
M.resolve_python = nil


local function default_runner()
  if uv.fs_stat('pytest.ini') then
    return 'pytest'
  elseif uv.fs_stat('manage.py') then
    return 'django'
  else
    return 'unittest'
  end
end

--- Table to register test runners.
--- Built-in are test runners for unittest, pytest and django.
--- The key is the test runner name, the value a function to generate the
--- module name to run and its arguments. See |dap-python.TestRunner|
---@type table<string, TestRunner>
M.test_runners = {}


local is_windows = function()
  return vim.fn.has("win32") == 1
end


---@param venv string
---@return string
local function python_exe(venv)
  if is_windows() then
    return venv .. '\\Scripts\\python.exe'
  end
  return venv .. '/bin/python'
end


local function roots()
  return coroutine.wrap(function()
    local cwd = vim.fn.getcwd()
    coroutine.yield(cwd)

    local wincwd = vim.fn.getcwd(0)
    if wincwd ~= cwd then
      coroutine.yield(wincwd)
    end

    ---@diagnostic disable-next-line: deprecated
    local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients
    for _, client in ipairs(get_clients()) do
      if client.config.root_dir then
        coroutine.yield(client.config.root_dir)
      end
    end
  end)
end


local get_python_path = function()
  local venv_path = os.getenv('VIRTUAL_ENV')
  if venv_path then
    return python_exe(venv_path)
  end

  venv_path = os.getenv("CONDA_PREFIX")
  if venv_path then
    if is_windows() then
      return venv_path .. '\\python.exe'
    end
    return venv_path .. '/bin/python'
  end

  if M.resolve_python then
    assert(type(M.resolve_python) == "function", "resolve_python must be a function")
    return M.resolve_python()
  end

  for root in roots() do
    for _, folder in ipairs({"venv", ".venv", "env", ".env"}) do
      local path = root .. "/" .. folder
      local stat = uv.fs_stat(path)
      if stat and stat.type == "directory" then
        return python_exe(path)
      end
    end
  end

  return nil
end


local enrich_config = function(config, on_config)
  if not config.pythonPath and not config.python then
    config.pythonPath = get_python_path()
  end
  on_config(config)
end


local default_setup_opts = {
  include_configs = true,
  console = 'integratedTerminal',
  pythonPath = nil,
}

local default_test_opts = {
  console = 'integratedTerminal'
}


local function load_dap()
  local ok, dap = pcall(require, 'dap')
  assert(ok, 'nvim-dap is required to use dap-python')
  return dap
end


local function get_module_path()
  if is_windows() then
    return vim.fn.expand('%:.:r:gs?\\?.?')
  else
    return vim.fn.expand('%:.:r:gs?/?.?')
  end
end


---@return string[]
local function flatten(...)
  local argc = select("#", ...)
  local result = {}
  for i = 1, argc do
    local arg = select(i, ...)
    if type(arg) == "table" then
      vim.list_extend(result, arg)
    else
      table.insert(result, arg)
    end
  end
  return result
end


---@private
---@param classnames string[]|string
---@param methodname string?
function M.test_runners.unittest(classnames, methodname)
  local test_path = table.concat(flatten(get_module_path(), classnames, methodname), '.')
  local args = {'-v', test_path}
  return 'unittest', args
end


---@private
---@param classnames string[]|string
---@param methodname string?
function M.test_runners.pytest(classnames, methodname)
  local path = vim.fn.expand('%:p')
  local test_path = table.concat(flatten({path, classnames, methodname}), '::')
  -- -s "allow output to stdout of test"
  local args = {'-s', test_path}
  return 'pytest', args
end


---@private
---@param classnames string[]|string
---@param methodname string?
function M.test_runners.django(classnames, methodname)
  local path = get_module_path()
  local test_path = table.concat(flatten({path, classnames, methodname}), '.')
  local args = {'test', test_path}
  return 'django', args
end


--- Register the python debug adapter
---@param adapter_python_path string|nil Path to the python interpreter. Path must be absolute or in $PATH and needs to have the debugpy package installed. Default is `python3`
---@param opts SetupOpts|nil See |dap-python.SetupOpts|
function M.setup(adapter_python_path, opts)
  local dap = load_dap()
  adapter_python_path = adapter_python_path and vim.fn.expand(vim.fn.trim(adapter_python_path), true) or 'python3'
  opts = vim.tbl_extend('keep', opts or {}, default_setup_opts)
  dap.adapters.python = function(cb, config)
    if config.request == 'attach' then
      ---@diagnostic disable-next-line: undefined-field
      local port = (config.connect or config).port
      ---@diagnostic disable-next-line: undefined-field
      local host = (config.connect or config).host or '127.0.0.1'
      cb({
        type = 'server',
        port = assert(port, '`connect.port` is required for a python `attach` configuration'),
        host = host,
        enrich_config = enrich_config,
        options = {
          source_filetype = 'python',
        }
      })
    else
      cb({
        type = 'executable';
        command = adapter_python_path;
        args = { '-m', 'debugpy.adapter' };
        enrich_config = enrich_config;
        options = {
          source_filetype = 'python',
        }
      })
    end
  end
  dap.adapters.debugpy = dap.adapters.python

  if opts.include_configs then
    local configs = dap.configurations.python or {}
    dap.configurations.python = configs
    table.insert(configs, {
      type = 'python';
      request = 'launch';
      name = 'Launch file';
      program = '${file}';
      console = opts.console;
      pythonPath = opts.pythonPath,
    })
    table.insert(configs, {
      type = 'python';
      request = 'launch';
      name = 'Launch file with arguments';
      program = '${file}';
      args = function()
        local args_string = vim.fn.input('Arguments: ')
        return vim.split(args_string, " +")
      end;
      console = opts.console;
      pythonPath = opts.pythonPath,
    })
    table.insert(configs, {
      type = 'python';
      request = 'attach';
      name = 'Attach remote';
      connect = function()
        local host = vim.fn.input('Host [127.0.0.1]: ')
        host = host ~= '' and host or '127.0.0.1'
        local port = tonumber(vim.fn.input('Port [5678]: ')) or 5678
        return { host = host, port = port }
      end;
    })
    table.insert(configs, {
      type = 'python',
      request = 'launch',
      name = 'Run doctests in file',
      module = 'doctest',
      args = { "${file}" },
      noDebug = true,
      console = opts.console,
      pythonPath = opts.pythonPath,
    })
  end
end


local function get_node_text(node)
  if vim.treesitter.get_node_text then
    return vim.treesitter.get_node_text(node, 0)
  end
  local row1, col1, row2, col2 = node:range()
  if row1 == row2 then
    row2 = row2 + 1
  end
  local lines = api.nvim_buf_get_lines(0, row1, row2, true)
  if #lines == 1 then
    return (lines[1]):sub(col1 + 1, col2)
  end
  return table.concat(lines, '\n')
end


--- Reverse list inline
---@param list any[]
local function reverse(list)
  local len = #list
  for i = 1, math.floor(len * 0.5) do
    local opposite = len - i + 1
    list[i], list[opposite] = list[opposite], list[i]
  end
end


---@param source string|integer
---@param subject "function"|"class"
---@param end_row integer? defaults to cursor
---@return TSNode[]
function M._get_nodes(source, subject, end_row)
  end_row = end_row or api.nvim_win_get_cursor(0)[1]
  local query_text = [[
    (function_definition
      name: (identifier) @function
    )

    (class_definition
      name: (identifier) @class
    )
  ]]
  local lang = "python"
  local query = (vim.treesitter.query.parse
    and vim.treesitter.query.parse(lang, query_text)
    or vim.treesitter.parse_query(lang, query_text)
  )
  local parser = (
    type(source) == "number"
    and vim.treesitter.get_parser(source, lang)
    or vim.treesitter.get_string_parser(source --[[@as string]], lang)
  )
  local trees = parser:parse()
  local root = trees[1]:root()
  local nodes = {}
  for id, node in query:iter_captures(root, source, 0, end_row) do
    local capture = query.captures[id]
    if capture == subject then
      table.insert(nodes, node)
    end
  end
  if not next(nodes) then
    return nodes
  end
  if subject == "function" then
    local result = nodes[#nodes]
    local parent = result
    while parent ~= nil do
      if parent:type() == "function_definition" then
        local ident = parent:child(1)
        assert(ident:type() == "identifier")
        result = ident
      end
      parent = parent:parent()
    end
    return { result }
  elseif subject == "class" then
    local last = nodes[#nodes]
    local parent = last
    local results = {}
    while parent ~= nil do
      if parent:type() == "class_definition" then
        local ident = parent:child(1)
        assert(ident:type() == "identifier")
        table.insert(results, ident)
      end
      parent = parent:parent()
    end
    reverse(results)
    return results
  else
    error("Expected subject 'function' or 'class', not: " .. subject)
  end
end


---@param classnames string[]
---@param methodname string?
---@param opts DebugOpts
local function trigger_test(classnames, methodname, opts)
  local test_runner = opts.test_runner or (M.test_runner or default_runner)
  if type(test_runner) == "function" then
    test_runner = test_runner()
  end
  local runner = M.test_runners[test_runner]
  if not runner then
    vim.notify('Test runner `' .. test_runner .. '` not supported', vim.log.levels.WARN)
    return
  end
  assert(type(runner) == "function", "Test runner must be a function")
  -- for BWC with custom runners which expect a string instead of a list of strings
  local classes = #classnames == 1 and classnames[1] or classnames
  local module, args = runner(classes, methodname)
  local config = {
    name = table.concat(flatten(classnames, methodname), '.'),
    type = 'python',
    request = 'launch',
    module = module,
    args = args,
    console = opts.console
  }
  load_dap().run(vim.tbl_extend('force', config, opts.config or {}))
end


--- Run test class above cursor
---@param opts? DebugOpts See |dap-python.DebugOpts|
function M.test_class(opts)
  opts = vim.tbl_extend('keep', opts or {}, default_test_opts)
  local candidates = M._get_nodes(0, "class")
  if not candidates then
    print('No test class found near cursor')
    return
  end
  local names = vim.tbl_map(get_node_text, candidates)
  trigger_test(names, nil, opts)
end


---@param node TSNode
---@result TSNode[]
local function get_parent_classes(node)
  local parent = node:parent()
  local result = {}
  while parent ~= nil do
    if parent:type() == "class_definition" then
      local ident = parent:child(1)
      assert(ident and ident:type() == "identifier")
      table.insert(result, ident)
    end
    parent = parent:parent()
  end
  reverse(result)
  return result
end


--- Run the test method above cursor
---@param opts? DebugOpts See |dap-python.DebugOpts|
function M.test_method(opts)
  opts = vim.tbl_extend('keep', opts or {}, default_test_opts)
  local functions = M._get_nodes(0, "function")
  if not functions then
    print('No test method found near cursor')
    return
  end
  local fn = functions[1]
  local parent_classes = get_parent_classes(fn)
  local classnames = vim.tbl_map(get_node_text, parent_classes)
  trigger_test(classnames, get_node_text(fn), opts)
end


--- Strips extra whitespace at the start of the lines
--
-- >>> remove_indent({'    print(10)', '    if True:', '        print(20)'})
-- {'print(10)', 'if True:', '    print(20)'}
local function remove_indent(lines)
  local offset = nil
  for _, line in ipairs(lines) do
    local first_non_ws = line:find('[^%s]') or 0
    if first_non_ws >= 1 and (not offset or first_non_ws < offset) then
      offset = first_non_ws
    end
  end
  if offset > 1 then
    assert(offset)
    return vim.tbl_map(function(x) return string.sub(x, offset) end, lines)
  else
    return lines
  end
end


--- Debug the selected code
---@param opts? DebugOpts
function M.debug_selection(opts)
  opts = vim.tbl_extend('keep', opts or {}, default_test_opts)
  local start_row, _ = unpack(api.nvim_buf_get_mark(0, '<'))
  local end_row, _ = unpack(api.nvim_buf_get_mark(0, '>'))
  local lines = api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  local code = table.concat(remove_indent(lines), '\n')
  local config = {
    type = 'python',
    request = 'launch',
    code = code,
    console = opts.console
  }
  load_dap().run(vim.tbl_extend('force', config, opts.config or {}))
end



---@class PathMapping
---@field localRoot string
---@field remoteRoot string


---@class DebugpyConfig
---@field django boolean|nil Enable django templates. Default is `false`
---@field gevent boolean|nil Enable debugging of gevent monkey-patched code. Default is `false`
---@field jinja boolean|nil Enable jinja2 template debugging. Default is `false`
---@field justMyCode boolean|nil Debug only user-written code. Default is `true`
---@field pathMappings PathMapping[]|nil Map of local and remote paths.
---@field pyramid boolean|nil Enable debugging of pyramid applications
---@field redirectOutput boolean|nil Redirect output to debug console. Default is `false`
---@field showReturnValue boolean|nil Shows return value of function when stepping
---@field sudo boolean|nil Run program under elevated permissions. Default is `false`

---@class DebugpyLaunchConfig : DebugpyConfig
---@field module string|nil Name of the module to debug
---@field program string|nil Absolute path to the program
---@field code string|nil Code to execute in string form
---@field python string[]|nil Path to python executable and interpreter arguments
---@field args string[]|nil Command line arguments passed to the program
---@field console DebugpyConsole See |dap-python.DebugpyConsole|
---@field cwd string|nil Absolute path to the working directory of the program being debugged.
---@field env table|nil Environment variables defined as key value pair
---@field stopOnEntry boolean|nil Stop at first line of user code.


---@class DebugOpts
---@field console DebugpyConsole See |dap-python.DebugpyConsole|
---@field test_runner "unittest"|"pytest"|"django"|string name of the test runner. Default is |dap-python.test_runner|
---@field config DebugpyConfig Overrides for the configuration

---@class SetupOpts
---@field include_configs boolean Add default configurations
---@field console DebugpyConsole See |dap-python.DebugpyConsole|
---@field pythonPath string|nil Path to python interpreter. Uses interpreter from `VIRTUAL_ENV` environment variable or `adapter_python_path` by default


---@alias TestRunner fun(classname: string|string[], methodname: string?):string, string[]

---@alias DebugpyConsole "internalConsole"|"integratedTerminal"|"externalTerminal"|nil

return M
