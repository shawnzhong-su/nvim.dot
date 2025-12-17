-- Language tooling for React (TypeScript/TSX) and Python in LazyVim
return {
  -- Language presets
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.json" },

  -- Additional formatters/linters installed via mason
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        -- JavaScript/TypeScript
        "eslint_d",
        "prettierd",
        "biome",
        -- Python
        "ruff",
        "ruff_lsp",
        "black",
        "isort",
      })
    end,
  },

  -- Treesitter parsers to cover React and Python stacks
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
}
