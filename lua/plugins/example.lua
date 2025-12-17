-- React (TS/TSX) + Python IDE add‑ons for LazyVim
-- Relies on the built‑in extras.lang.typescript/python already imported in lua/config/lazy.lua
return {
  -- Mason: install common LSP/format/lint/debug tools up front
  {
    "mason-org/mason.nvim",
    name = "mason.nvim", -- upstream rename
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        -- JS/TS/React
        "eslint_d",
        "prettierd",
        "biome",
        "js-debug-adapter",
        "tailwindcss-language-server",
        -- Python
        "pyright",
        "black",
        "isort",
        "debugpy",
      })
    end,
  },

  -- Treesitter parsers for both stacks
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      })
    end,
  },

  -- Formatter preferences (Conform is LazyVim's default formatter)
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.javascript = { "prettierd", "biome" }
      opts.formatters_by_ft.typescript = { "prettierd", "biome" }
      opts.formatters_by_ft.javascriptreact = { "prettierd", "biome" }
      opts.formatters_by_ft.typescriptreact = { "prettierd", "biome" }
      opts.formatters_by_ft.python = { "black", "isort" }
    end,
  },

  -- Lint on save (eslint_d)
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.javascript = { "eslint_d" }
      opts.linters_by_ft.typescript = { "eslint_d" }
      opts.linters_by_ft.javascriptreact = { "eslint_d" }
      opts.linters_by_ft.typescriptreact = { "eslint_d" }
    end,
  },

  -- Virtualenv picker tuned for Miniconda
  {
    "linux-cultist/venv-selector.nvim",
    opts = function(_, opts)
      local home = vim.env.HOME
      local conda_root = vim.env.CONDA_PREFIX or (home and (home .. "/miniconda3") or nil)
      opts.search = opts.search or {}
      if conda_root then
        -- Find env pythons under miniconda base
        opts.search.conda_envs = {
          command = string.format("fd /python$ %s/envs --full-path --color never -E /proc -a", conda_root),
          type = "anaconda",
        }
        -- Also include base environment python
        opts.search.conda_base = {
          command = string.format("fd /python$ %s/bin --full-path --color never -E /proc -a", conda_root),
          type = "anaconda",
        }
      end
      opts.options = opts.options or {}
      opts.options.notify_user_on_venv_activation = true
    end,
  },

  -- Auto-import missing symbols via LSP (Pyright)
  {
    "stevanmilic/nvim-lspimport",
    keys = {
      {
        "<leader>ai",
        function()
          require("lspimport").import()
        end,
        desc = "Auto import symbol",
      },
    },
  },

  -- Disable Ruff LSP variants (use Pyright only)
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false, -- 关闭行尾文字，让界面更干净
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
        },
      },
      -- 禁用 Ruff 以防与 Pyright 冲突 (按你原代码要求)
      servers = {
        ruff = { enabled = false },
        ruff_lsp = { enabled = false },
      },
    },
  },

  -- Debugging: js/ts via vscode-js, python via debugpy
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      "mfussenegger/nvim-dap-python",
      "mxsdev/nvim-dap-vscode-js",
      "jay-babu/mason-nvim-dap.nvim",
    },
    config = function()
      local dap = require("dap")

      -- JS/TS debug adapter from mason (pwa-node)
      require("dap-vscode-js").setup({
        debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter",
        adapters = { "pwa-node" },
      })

      local js_languages = { "javascript", "javascriptreact", "typescript", "typescriptreact" }
      for _, lang in ipairs(js_languages) do
        dap.configurations[lang] = dap.configurations[lang] or {}
        table.insert(dap.configurations[lang], {
          type = "pwa-node",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          cwd = "${workspaceFolder}",
          sourceMaps = true,
          protocol = "inspector",
          console = "integratedTerminal",
        })
        table.insert(dap.configurations[lang], {
          type = "pwa-node",
          request = "attach",
          name = "Attach (9229)",
          processId = require("dap.utils").pick_process,
          cwd = "${workspaceFolder}",
          port = 9229,
        })
      end

      -- Python debug adapter from mason
      pcall(function()
        require("dap-python").setup("debugpy-adapter")
      end)
    end,
  },

  -- Install dap adapters via mason-nvim-dap (but keep python adapter from nvim-dap-python)
  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "js-debug-adapter", "debugpy" })
      opts.handlers = opts.handlers or {}
      opts.handlers.python = function() end
    end,
  },

  -- Testing: Jest for React, pytest for Python
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "nvim-neotest/neotest-jest",
      "nvim-neotest/neotest-python",
    },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      table.insert(
        opts.adapters,
        require("neotest-jest")({
          jestCommand = "npm test --",
          cwd = function(path)
            return vim.fn.getcwd()
          end,
        })
      )
      table.insert(
        opts.adapters,
        require("neotest-python")({
          runner = "pytest",
        })
      )
    end,
  },
}
