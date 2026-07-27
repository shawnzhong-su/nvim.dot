---
doc_type: feature-ff-note
feature: python-venv-selection
date: 2026-07-17
requirement:
tags: [python, neovim, virtualenv, lsp]
---

## 做了什么
启用 ShawnVim 的 Python extra：项目内 `.venv` 自动激活，其他环境可用 picker 选择并在当前 Neovim 会话内按 project root 记忆；选择结果同步给 Neovim 环境和 Pyright/BasedPyright。

## 改了哪些
- `shawnvim.json:2` — 启用 `shawnvim.plugins.extras.lang.python`。
- `lazy-lock.json:32` — 锁定 `venv-selector.nvim`。
- `lua/plugins/init.lua:3` — 用稳定 root、同步 buffer 切换和公开 LSP 配置通知兼容 Neovim 0.12；禁用当前依赖版本存在竞态的跨会话自动缓存。

## 怎么验证的
用临时项目和仅存在于目标环境的模块验证：项目 `.venv` 无操作自动解析；外部环境手动选择后解析成功，并在 A→B 无环境→A 切换中同步清理/恢复。`.pyi` 与无扩展 Python buffer 均不会继承 A；Pyright/BasedPyright、命令、键位、夹具及缓存清理均通过。
