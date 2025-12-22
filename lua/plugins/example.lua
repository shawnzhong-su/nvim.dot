-- React (TS/TSX) + Python IDE add‑ons for LazyVim
-- 完整配置文件：集成了补全、自动导入、调试、测试及快捷键优化

return {
  -----------------------------------------------------------------------------
  -- 1. 核心补全引擎 (替代 nvim-cmp 和 lspimport)
  -----------------------------------------------------------------------------
  {
    "saghen/blink.cmp",
    version = "*",
    opts = {
      -- 定义快捷键映射
      keymap = {
        preset = "none", -- 禁用默认预设，我们要自定义

        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide" },
        -- 设置 Tab 键：如果有补全建议，则确认建议；否则执行默认 Tab 行为
        ["<Tab>"] = { "accept", "fallback" },

        -- 设置方向键或上下键在菜单中切换
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },

        -- 文档翻页
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
      },

      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
      },

      completion = {
        -- 核心：确认补全时自动导入
        list = { selection = { preselect = true, auto_insert = true } },
        menu = { border = "rounded" },
        documentation = { window = { border = "rounded" }, auto_show = true },
      },

      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
  },

  -- 显式禁用旧的 lspimport，防止报错干扰
  { "stevanmilic/nvim-lspimport", enabled = false },

  -----------------------------------------------------------------------------
  -- 2. LSP & 自动导入配置 (BasedPyright + TypeScript)
  -----------------------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false, -- 保持界面整洁
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = { border = "rounded", source = "always" },
      },
      servers = {
        -- 禁用 Ruff 以防冲突
        ruff = { enabled = false },
        ruff_lsp = { enabled = false },
        -- 禁用原版 Pyright
        pyright = { enabled = false },

        -- 启用 BasedPyright：提供比原版更强的 Code Action 和自动导入支持
        -- 启用 BasedPyright
        basedpyright = {
          -- 关键修复：确保即使在单个文件或特殊路径下也能启动
          root_dir = function(fname)
            local util = require("lspconfig.util")
            -- 寻找项目标志文件，如果找不到，就以当前文件所在目录作为根目录
            return util.root_pattern(".git", "setup.py", "pyproject.toml", "requirements.txt")(fname)
              or vim.fs.dirname(fname)
          end,
          settings = {
            basedpyright = {
              analysis = {
                autoImportCompletions = true,
                diagnosticMode = "workspace",
                typeCheckingMode = "basic",
              },
            },
          },
        },
        -- TailwindCSS
        tailwindcss = {},
      },
    },
  },

  -----------------------------------------------------------------------------
  -- 3. Mason 工具安装 (保留插件原名: mason-org/mason.nvim)
  -----------------------------------------------------------------------------
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        -- TS/JS/React
        "eslint_d",
        "prettierd",
        "biome",
        "js-debug-adapter",
        "tailwindcss-language-server",
        -- Python (使用 basedpyright 替换 pyright)
        "basedpyright",
        "black",
        "isort",
        "debugpy",
      })
    end,
  },

  -----------------------------------------------------------------------------
  -- 4. 格式化 (Conform) 与 代码检查 (Lint)
  -----------------------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        javascript = { "prettierd", "biome" },
        typescript = { "prettierd", "biome" },
        javascriptreact = { "prettierd", "biome" },
        typescriptreact = { "prettierd", "biome" },
        python = { "isort", "black" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
      },
    },
  },

  -----------------------------------------------------------------------------
  -- 5. Python 虚拟环境切换 (Miniconda 优化)
  -----------------------------------------------------------------------------
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp", -- 2025 推荐分支
    opts = function(_, opts)
      local home = vim.env.HOME
      local conda_root = vim.env.CONDA_PREFIX or (home and (home .. "/miniconda3") or nil)
      opts.settings = {
        options = { notify_user_on_venv_activation = true },
        search = {
          conda = {
            command = conda_root and (string.format("fd /python$ %s/envs --full-path --color never", conda_root))
              or nil,
          },
        },
      }
    end,
  },

  -----------------------------------------------------------------------------
  -- 6. 调试 (DAP) & 测试 (Neotest)
  -----------------------------------------------------------------------------
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
      -- JS/TS 调试
      require("dap-vscode-js").setup({
        debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter",
        adapters = { "pwa-node" },
      })
      for _, lang in ipairs({ "javascript", "typescript", "typescriptreact" }) do
        dap.configurations[lang] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = "${workspaceFolder}",
          },
        }
      end
      -- Python 调试
      require("dap-python").setup("debugpy-adapter")
    end,
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "nvim-neotest/neotest-jest", "nvim-neotest/neotest-python" },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      table.insert(opts.adapters, require("neotest-jest")({ jestCommand = "npm test --" }))
      table.insert(opts.adapters, require("neotest-python")({ runner = "pytest" }))
    end,
  },

  -----------------------------------------------------------------------------
  -- 7. 快捷键与交互优化 (Flash + Surround)
  -----------------------------------------------------------------------------
  {
    "folke/flash.nvim",
    opts = { modes = { char = { enabled = false } } },
    keys = {
      { "s", mode = { "n", "x", "o" }, false }, -- 释放 s 键给 surround
      { "S", mode = { "n", "x", "o" }, false },
      {
        "<leader>j",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
    },
  },
  {
    -- 保留插件原名: nvim-mini/mini.surround
    "nvim-mini/mini.surround",
    opts = {
      mappings = {
        add = "sa",
        delete = "sd",
        find = "sf",
        find_left = "sF",
        highlight = "sh",
        replace = "sr",
        update_n_lines = "sn",
      },
    },
  },

  -----------------------------------------------------------------------------
  -- 8. 语法高亮 (Treesitter)
  -----------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, {
          "bash",
          "html",
          "javascript",
          "json",
          "lua",
          "markdown",
          "python",
          "tsx",
          "typescript",
          "yaml",
          "regex",
        })
      end
    end,
  },
}
