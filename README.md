# nvim.dot

My LazyVim-based Neovim config with built-in support for React/TypeScript and Python development.

## What you get
- LazyVim language extras for TypeScript/React, Python, and JSON.
- Mason ensures common formatters/linters such as eslint_d, prettierd, biome, ruff, black, and isort are available.
- Treesitter parsers for JavaScript/TypeScript/TSX, Python, JSON, Markdown, and more.

## Verify the setup
1. Launch Neovim and wait for Lazy to install plugins. Use `:Lazy` to confirm there are no pending installs.
2. Run `:Mason` and check that `tsserver`, `pyright` (or `ruff_lsp`), and formatters are installed. Press `i` inside Mason to install any missing tool.
3. Open a React file (`.tsx/.ts`) or Python file and run `:LspInfo` to confirm the language server is attached. You should see completion via nvim-cmp and inline diagnostics.
4. For syntax highlighting and indentation, run `:checkhealth nvim-treesitter` and ensure the `tsx`, `typescript`, `javascript`, and `python` parsers are installed.
5. Save a file to verify formatting: `prettierd/biome` will handle TS/TSX/JS, while `black`/`isort` cover Python.

With these checks passing you can expect code completion, diagnostics, formatting, and tree-sitter highlighting to work for both React and Python projects.
