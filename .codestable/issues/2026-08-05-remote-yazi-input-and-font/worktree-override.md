# Worktree Override

- Reason: 本问题修改的是当前 macOS 的 VS Code 用户设置、应用偏好和本机字体，并要求立即修复实际 Remote SSH 会话；这些运行时用户资源无法在 Git linked worktree 中生效或验证。
- Scope: `~/Library/Application Support/Code/User/settings.json`、`com.microsoft.VSCode` 应用偏好、`~/Library/Fonts/FiraCodeNerdFont*.ttf`，以及本 issue 修复记录。
- Approval: 用户于 2026-08-05 明确要求“请你帮我马上修复”。
