---
doc_type: feature-review
feature: 2026-07-17-python-venv-selection
status: changes-requested
reviewer: subagent
reviewed: 2026-07-17
round: 2
lane_a_state: completed
lane_a_ref: "/root/python_venv_rereview"
lane_a_reason: ""
lane_b_state: unavailable
lane_b_ref: ""
lane_b_reason: "ocr LLM 后端 127.0.0.1:18080 未运行"
---

# python-venv-selection 代码审查报告

## 1. Scope And Inputs

- Design: none（feature-ff）
- Checklist: none（feature-ff）
- Evidence pack: none
- Gate results: none
- DoD results: none
- Implementation evidence: `python-venv-selection-ff-note.md` 与本轮真实 `.venv` 烟测
- Diff basis: `shawnvim.json`、`lazy-lock.json`、`lua/plugins/init.lua` 及 feature-ff 产物
- Review mode: initial
- Baseline dirty files: `.codestable/reference/*.md` 与 `runtime-manifest.json` 为 1.0.4 runtime preflight 同步，不属于功能 diff

### Independent Review

- Detection: 独立 Codex subagent 可用；OCR CLI 存在但 LLM 后端连接失败
- 环节 A 独立隔离 Task agent: independent-agent + completed
- 环节 B OCR CLI: unavailable
- OCR severity mapping: High→blocking/important, Medium→nit/suggestion, Low→discarded
- Merge policy: subagent findings 已与本地源码和可复现双项目测试逐条核验
- Gate effect: blocking / important 清零前不放行

## 2. Diff Summary

- 新增：`python-venv-selection-ff-note.md`
- 修改：`shawnvim.json`、`lazy-lock.json`、`lua/plugins/init.lua`
- 删除：none
- 未跟踪 / staged：feature 目录未跟踪；staged none
- 风险热点：多项目切换、缓存恢复与 LSP attach 时序

## 3. Adversarial Pass

- 假设的生产 bug：项目 A 的全局解释器状态在项目 B attach 或延迟缓存恢复时泄漏给 B。
- 主动攻击过的反例：A/B 双 root、B 无缓存、A/B 快速切换、缓存先于/后于 LSP attach。
- 结果：跨项目解释器泄漏已本地复现并升级为 REV-001；上游延迟恢复竞态升级为 REV-002。

## 4. Findings

### blocking

- [ ] REV-001 `lua/plugins/init.lua:48` `LspAttach` 直接使用全局 `selector.python()`，未校验 `args.buf` 所属 project root。
  - Evidence: A 选择 `.venv` 后打开无缓存 B，B 的 Pyright `pythonPath` 实测为 A 的解释器；subagent 同时从 `venv-selector` 全局状态实现确认。
  - Impact: B 的导入解析、诊断和索引持续使用错误环境，核心多项目行为不可信。
  - Expected fix scope: attach 时只允许当前 active root 与目标 buffer root 匹配的解释器进入 client，并补 A/B 隔离测试。

### important

- [ ] REV-002 `venv-selector.nvim/lua/venv-selector/autocmds.lua:76` 上游缓存恢复延迟一秒且未验证 buffer 仍为当前项目。
  - Evidence: 延迟回调仅检查 buffer 有效/未禁用；随后会重写全局 `VIRTUAL_ENV`、PATH 和 selector 状态。
  - Impact: 一秒内从 A 切到 B 时，过期 A 回调可能覆盖 B，终端、后续 LSP attach 和状态显示取决于异步顺序。
  - Expected fix scope: 本地集成须确保过期恢复不能成为最终状态，并用快速切换后稳定态断言验证。

### nit

- [ ] REV-003 `lua/plugins/init.lua:20` 未根据 `client:notify()` 返回值决定 hook 成功计数。

### suggestion

- [ ] REV-004 `lua/plugins/init.lua:56` 明确记录 `opts.hooks` 是有意替换上游 Neovim 0.12 不兼容的默认重启 hook。

### learning

- Neovim 0.12 的运行时配置需同步 `client.settings` 与 `client.config.settings`，Pyright/BasedPyright 使用 `python.pythonPath`。

### praise

- settings 深合并保留了非 Python 配置；锁文件只新增目标插件；空 client 与空解释器均有保护。

## 5. Test And QA Focus

- QA 必须重点复核：A/B 不同 root 与 venv；B 无缓存；A/B 均有缓存并在一秒内切换；缓存与 LSP attach 两种先后顺序。
- Evidence pack residual risks / gate warnings：OCR 不可用；BasedPyright 尚未真实跑完整选择链。
- 建议新增或加强的测试：用仅存在于各自 venv 的模块验证真实解析，而不只读 Lua settings。
- 不能靠 review 完全确认的点：依赖公开停用 API不会恢复本地直接写入的 `pythonPath`。

## 6. Residual Risk

- 替换默认 hook 后，`deactivate()` 不会管理未带 `_venv_selector` 标记的客户端；本轮先保证选择、缓存恢复和多项目隔离，停用流程需在复审中重新评估。

## 7. Verdict

- Status: changes-requested
- Next: 返回 `cs-feat` Quick review-fix，修复 REV-001/REV-002 后做完整独立复审。

## 8. Focused Closure

none

## 9. Round 2 Full Rereview

- Reviewer: `/root/python_venv_rereview`
- Verdict: changes-requested
- Closed: REV-001、REV-003、REV-004
- Partially closed: REV-002；普通 `.py` 最终状态可稳定，但上游异步激活本身未被 generation 阻止。
- New blocking: `BufEnter`/`FileType` 共用 pattern 会遗漏 `.pyi` 与无扩展 Python buffer。
- New important: 1200ms 错环境窗口、`retrieve()` 先激活后回调、清理未覆盖 DAP/LSP、LSP attach 前后 root 不稳定。
- Required direction: 不再对不可取消的上游异步缓存做事后修补；使用同步且稳定的 project-root 转换契约后完整复审。
