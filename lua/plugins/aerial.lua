-- Symbols outline powered by aerial.nvim
return {
  "stevearc/aerial.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "LspAttach",
  opts = {
    backends = { "lsp", "treesitter", "markdown" },
    attach_mode = "global",
    show_guides = true,
    layout = {
      min_width = 28,
      default_direction = "prefer_right",
    },
    guides = {
      mid_item = "├─",
      last_item = "└─",
      nested_top = "│ ",
      whitespace = "  ",
    },
    disable_max_lines = 50000,
  },
  keys = {
    { "<leader>to", "<cmd>AerialToggle!<CR>", desc = "Toggle symbols outline" },
    { "[s", "<cmd>AerialPrev<CR>", desc = "Prev symbol" },
    { "]s", "<cmd>AerialNext<CR>", desc = "Next symbol" },
  },
}
