# Dashboard 上的 Project 如何界定

## 背景

当前 dashboard 的 `Projects` 入口由 Snacks picker 提供。需要明确这里的 project 是怎样进入候选列表的，以及它和 Git 分支、当前工作目录、LSP root、session 的关系。本结论基于 `lazy-lock.json` 当前锁定的 `snacks.nvim` commit `882c996cf28183f4d63640de0b4c02ec886d01f2`；不讨论 Git 分支。

## 结论

dashboard 上按 `p` 会调用 `Snacks.picker.projects()`。这里的 **project 是一个候选根目录**，默认由三类来源合并、按规范化路径去重：

1. **最近文件的 Git 根目录（主要来源）**：遍历仍然存在且通过 picker filter 的 `vim.v.oldfiles`，对每个文件向父目录查找 `.git`，找到的目录视为 project；没有 Git root 的最近文件不会单独形成 project。Git root 查找不执行 `git rev-parse`，也不读取 branch；若一路找不到 `.git`，仅以环境变量 `GIT_WORK_TREE` 作为 fallback。
2. **显式配置的 `projects`**：当前没有项目级覆写，因而默认为空。
3. **开发目录扫描**：默认扫描 `~/dev` 和 `~/projects`，最多深入两层，用 `fd`/`fdfind` 查找 `.git`、`_darcs`、`.hg`、`.bzr`、`.svn`、`package.json` 或 `Makefile`，并把 marker 的父目录作为 project。没有 `fd`/`fdfind` 时，这部分不可用，但最近 Git roots 和显式 `projects` 仍可产生候选。

候选没有固定数量上限；picker 会启用 frecency，按 `score` 降序再按原始 `idx` 排序，且不给当前 cwd 额外加分。目录 frecency 是其下已记录文件 frecency 的总和，记录持久化于 Neovim data 目录下的 `snacks/picker-frecency.sqlite3`，SQLite 不可用时退回 `.dat`。

选中 project 后，默认动作是先切换目录，再尝试恢复该目录对应的 session；未恢复 session 时打开文件 picker。因此 session 是选择后的动作，不是 project 候选的数据源。

简言之：**当前 project ≈ 最近打开文件所属的 Git 仓库根目录，再加上预设开发目录里通过 root marker 扫描出来的目录**。它不等于 Git branch、当前 cwd、LSP workspace/root 或 persistence 的 session 列表。

## 证据

- `lua/shawnvim/plugins/extras/editor/snacks_picker.lua:170-177`：dashboard 的 `Projects` 按钮执行 `Snacks.picker.projects()`。
- `lazy-lock.json:27`：当前 Snacks 锁定版本为 `882c996cf28183f4d63640de0b4c02ec886d01f2`。
- `~/.local/share/nvim/lazy/snacks.nvim/lua/snacks/picker/config/sources.lua:880-900`：projects picker 使用 `recent_projects`；默认 `dev = { "~/dev", "~/projects" }`、`recent = true`、root patterns、`confirm = "load_session"` 及 frecency 排序配置。
- `~/.local/share/nvim/lazy/snacks.nvim/lua/snacks/picker/source/recent.lua:7-25`：recent 来源读取 `vim.v.oldfiles`，规范化、去重并排除不存在或不匹配 filter 的文件。
- `~/.local/share/nvim/lazy/snacks.nvim/lua/snacks/picker/source/recent.lua:57-121`：候选依次合并 recent Git roots、显式 `projects` 和 `dev` 扫描结果；`dev` 默认 `max-depth = 2`，并统一按目录去重。
- `~/.local/share/nvim/lazy/snacks.nvim/lua/snacks/git.lua:17-46`：沿路径父目录查找 `.git`，找不到时 fallback 到 `GIT_WORK_TREE`。
- `~/.local/share/nvim/lazy/snacks.nvim/lua/snacks/picker/actions.lua:661-684`：选中后 `chdir`、尝试加载 session，失败则打开文件 picker。
- `~/.local/share/nvim/lazy/snacks.nvim/lua/snacks/picker/core/frecency.lua:10-16,28-41,92-118`：frecency 存储、30 天半衰期及目录得分为其下文件得分总和。
