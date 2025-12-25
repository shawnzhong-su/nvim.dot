return {
  -----------------------------------------------------------------------------
  -- 1. 核心补全引擎 (Blink.cmp - 替代 nvim-cmp)
  -----------------------------------------------------------------------------
  {
    "saghen/blink.cmp",
    version = "*",
    opts = {
      keymap = {
        preset = "none",
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide" },
        ["<Tab>"] = { "accept", "fallback" }, -- 接受建议或 fallback
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
      },
      completion = {
        list = { selection = { preselect = true, auto_insert = true } },
        menu = { border = "rounded" },
        documentation = { window = { border = "rounded" }, auto_show = true },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
  },

  -- 禁用 lspimport 以防冲突
  { "stevanmilic/nvim-lspimport", enabled = false },

  -----------------------------------------------------------------------------
  -- 2. LSP 配置 (集成 BasedPyright 修复)
  -----------------------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = { border = "rounded", source = "always" },
      },
      servers = {
        -- 禁用可能冲突的 Server
        ruff = { enabled = false },
        ruff_lsp = { enabled = false },
        pyright = { enabled = false },

        -- Python: BasedPyright (包含文档中的核心修复)
        basedpyright = {
          enabled = true,
          -- 修复 1: 强制指定命令路径，确保能找到 Mason 安装的 binary
          cmd = (function()
            local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/basedpyright-langserver"
            if vim.fn.executable(mason_bin) == 1 then
              return { mason_bin, "--stdio" }
            end
            return { "basedpyright-langserver", "--stdio" }
          end)(),

          -- 修复 2: 适配 Neovim 0.11+ 的 root_dir 签名 (bufnr, on_dir)
          root_dir = function(bufnr, on_dir)
            -- 处理 bufnr 为文件名或数字的情况
            local fname = bufnr
            if type(bufnr) == "number" then
              fname = vim.api.nvim_buf_get_name(bufnr)
            end

            -- 如果没有文件名，直接返回 nil
            if type(fname) ~= "string" or fname == "" then
              return nil
            end

            -- 获取目录
            local dir = vim.fs.dirname(fname)

            -- 寻找项目根目录标志
            local util = require("lspconfig.util")
            local root = util.root_pattern(".git", "setup.py", "pyproject.toml", "requirements.txt")(fname) or dir

            -- 如果传入了回调函数 (0.11+ 特性)，则调用它
            if type(on_dir) == "function" then
              on_dir(root)
              return
            end

            return root
          end,

          settings = {
            basedpyright = {
              analysis = {
                autoImportCompletions = true,
                diagnosticMode = "workspace",
                typeCheckingMode = "basic", -- 可根据需要改为 standard
              },
            },
          },
        },

        -- Frontend: TailwindCSS
        tailwindcss = {},
      },
    },
  },

  -----------------------------------------------------------------------------
  -- 3. Mason 工具链
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
        -- Python
        "basedpyright",
        "black",
        "isort",
        "debugpy",
      })
    end,
  },

  -----------------------------------------------------------------------------
  -- 4. 格式化 (Conform) & 代码检查 (Lint)
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
  -- 5. Python 虚拟环境 (Miniconda 增强)
  -----------------------------------------------------------------------------
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap-python" },
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
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv" },
    },
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
      -- JS/TS Debug
      require("dap-vscode-js").setup({
        debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter",
        adapters = { "pwa-node", "pwa-chrome" },
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
      -- Python Debug
      require("dap-python").setup(vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python")
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
  -- 7. 界面与交互优化
  -----------------------------------------------------------------------------
  {
    "folke/flash.nvim",
    opts = { modes = { char = { enabled = false } } },
    keys = {
      { "s", mode = { "n", "x", "o" }, false },
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
  -- 8. Treesitter 语法高亮
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
          "css",
        })
      end
    end,
  },
}
