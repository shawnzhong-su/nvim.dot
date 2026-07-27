-- Add personal plugin specs here.

local python_lsp = { pyright = true, basedpyright = true }
local python_root_markers = {
  "pyproject.toml",
  "setup.py",
  "setup.cfg",
  "requirements.txt",
  "Pipfile",
  "pyrightconfig.json",
  ".git",
}

local selected_python = {}
local lsp_baselines = {}
local active_root
local dap_resolver
local dap_resolver_captured = false

local initial_venv = vim.env.VIRTUAL_ENV
local initial_python = initial_venv and (initial_venv .. "/bin/python") or nil
local cwd = vim.uv.cwd()
local initial_root = cwd and (vim.fs.root(cwd, python_root_markers) or cwd) or nil

local function project_root(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
    return nil
  end

  local file = vim.api.nvim_buf_get_name(bufnr)
  local dir = file ~= "" and vim.fs.dirname(file) or nil
  return dir and (vim.fs.root(dir, python_root_markers) or dir) or nil
end

local function notify_settings(client, settings)
  client.settings = settings
  client.config.settings = vim.deepcopy(settings)
  local notified = client:notify("workspace/didChangeConfiguration", { settings = settings }) == true
  if not notified then
    vim.notify("Failed to update " .. client.name .. " with the selected Python environment", vim.log.levels.WARN)
  end
  return notified
end

local function set_python_path(client, python_path)
  if not client or not python_lsp[client.name] or not python_path or python_path == "" then
    return false
  end

  lsp_baselines[client.id] = lsp_baselines[client.id]
    or vim.tbl_deep_extend("force", {}, client.config.settings or {}, client.settings or {})
  local settings = vim.tbl_deep_extend(
    "force",
    {},
    client.config.settings or {},
    client.settings or {},
    { python = { pythonPath = python_path } }
  )
  return notify_settings(client, settings)
end

local function restore_python_clients(bufnr)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    local baseline = lsp_baselines[client.id]
    if python_lsp[client.name] and baseline then
      notify_settings(client, vim.deepcopy(baseline))
      lsp_baselines[client.id] = nil
    end
  end
end

local function capture_dap_resolver()
  if dap_resolver_captured then
    return
  end

  local has_dap = pcall(require, "dap")
  local has_dap_python, dap_python = pcall(require, "dap-python")
  if has_dap and has_dap_python then
    dap_resolver = dap_python.resolve_python
    dap_resolver_captured = true
  end
end

local function update_python_clients(python_path, _, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local root = project_root(bufnr)
  if not root then
    return 0
  end

  selected_python[root] = python_path
  active_root = root
  capture_dap_resolver()

  local updated = 0
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if set_python_path(client, python_path) then
      updated = updated + 1
    end
  end
  return updated
end

local function clear_active_environment(bufnr)
  local path = require("venv-selector.path")
  local venv = require("venv-selector.venv")
  path.remove_current()
  venv.unset_env_variables()
  venv.clear_active_state()
  restore_python_clients(bufnr)

  if dap_resolver_captured then
    require("dap-python").resolve_python = dap_resolver
  end
  active_root = nil
end

local function project_python(root)
  local python = root .. "/.venv/bin/python"
  return vim.fn.executable(python) == 1 and python or nil
end

local function activate_for_buffer(bufnr, python_path)
  local root = project_root(bufnr)
  if not root or vim.fn.executable(python_path) ~= 1 then
    return
  end

  require("venv-selector").activate_from_path(python_path, "venv")
  update_python_clients(python_path, "venv", bufnr)
end

local function sync_python_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype ~= "python" then
    return
  end

  local root = project_root(bufnr)
  if not root then
    return
  end

  local python = selected_python[root]
  if python and vim.fn.executable(python) ~= 1 then
    selected_python[root] = nil
    python = nil
  end
  if not python and package.loaded["venv-selector"] then
    local selector_python = require("venv-selector").python()
    local selector_root = require("venv-selector.venv").active_project_root()
    if selector_root == root and selector_python and vim.fn.executable(selector_python) == 1 then
      python = selector_python
      selected_python[root] = selector_python
    end
  end
  python = python or project_python(root)
  if not python and root == initial_root and initial_python and vim.fn.executable(initial_python) == 1 then
    python = initial_python
  end

  if python then
    activate_for_buffer(bufnr, python)
  elseif active_root then
    clear_active_environment(bufnr)
  end
end

return {
  {
    "linux-cultist/venv-selector.nvim",
    optional = true,
    init = function()
      local group = vim.api.nvim_create_augroup("ShawnVimPythonVenv", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "python",
        callback = function(args)
          sync_python_buffer(args.buf)
        end,
      })
      vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
        group = group,
        callback = function(args)
          sync_python_buffer(args.buf)
        end,
      })
      vim.api.nvim_create_autocmd("LspAttach", {
        group = group,
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          local root = project_root(args.buf)
          if client and root and selected_python[root] then
            set_python_path(client, selected_python[root])
          end
        end,
      })
    end,
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.enable_cached_venvs = false
      opts.options.cached_venv_automatic_activation = false
      -- Replace the upstream restart hook, which still relies on the pre-0.12
      -- client.attached_buffers shape.
      opts.hooks = { update_python_clients }
    end,
  },
}
