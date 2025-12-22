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
-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- lua/config/options.lua
if vim.g.neovide then
  -- 字体
  vim.o.guifont = "JetBrainsMono Nerd Font:h13"

  -- 光标动画
  vim.g.neovide_cursor_animation_length = 0.08
  vim.g.neovide_cursor_short_animation_length = 0.03
  vim.g.neovide_cursor_trail_size = 0.7

  -- 平滑闪烁（需要 guicursor 有 blinkwait/blinkon/blinkoff）
  vim.g.neovide_cursor_smooth_blink = true

  -- 平滑滚动 / 窗口动画
  vim.g.neovide_scroll_animation_length = 0.18
  vim.g.neovide_scroll_animation_far_lines = 1
  vim.g.neovide_position_animation_length = 0.12

  -- padding
  vim.g.neovide_padding_top = 6
  vim.g.neovide_padding_bottom = 6
  vim.g.neovide_padding_left = 8
  vim.g.neovide_padding_right = 8

  -- 让 smooth blink 真正生效：给所有模式一个 blink 配置
  -- 你也可以按模式细分，这里先给“够用且稳”的全局 a: 方案
  vim.opt.guicursor = "a:blinkwait700-blinkon400-blinkoff250"
end
