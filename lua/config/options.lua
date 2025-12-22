-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Prefer Pyright for Python
vim.g.lazyvim_python_lsp = "pyright"

vim.opt.scrolloff = 30

-- Show diagnostics in a floating window instead of inline virtual text
vim.diagnostic.config({
  virtual_text = false,
  float = { border = "rounded", source = "if_many" },
})

-- Manual diagnostic float: use LazyVim's default `gl` mapping (or `:lua vim.diagnostic.open_float()`)
