---
doc_type: issue-fix
issue: 2026-08-05-remote-yazi-input-and-font
path: fast-track
fix_date: 2026-08-05
tags: [vscode, yazi, remote-ssh, keyboard, nerd-font]
---

# 远程 Yazi 输入与图标显示修复记录

## 1. 问题描述

通过 VS Code Remote SSH 打开 Yazi 后，键盘导航有明显延迟；连续使用 `j` / `k` 时可能意外进入或打开文件；Nerd Font 图标显示异常。

## 2. 根因

- macOS 未对 VS Code 禁用长按字符选择，长按导航键不会稳定地产生连续按键事件。
- VS Code 未固定使用 `keyCode` 键盘分发，Linux 远程窗口中的重映射按键识别存在偏差风险。
- 集成终端配置使用普通 Fira Code，本机此前未安装带图标字形的 Nerd Font。Remote SSH 的终端仍由本机 VS Code 渲染，因此字体必须安装并配置在本机。

## 3. 修复方案

- 为 `com.microsoft.VSCode` 设置 `ApplePressAndHoldEnabled=false`，恢复连续按键重复。
- 在 VS Code 用户设置中配置 `"keyboard.dispatch": "keyCode"`。
- 安装 `font-fira-code-nerd-font` 3.5.0，并将集成终端首选字体设为 `FiraCode Nerd Font Mono`。

## 4. 改动文件清单

- `~/Library/Application Support/Code/User/settings.json`：新增键盘分发设置，更新集成终端字体族。
- macOS 应用偏好 `com.microsoft.VSCode`：禁用长按字符选择。
- `~/Library/Fonts/FiraCodeNerdFont*.ttf`：由 Homebrew Cask 安装 Nerd Font 3.5.0。

## 5. 验证结果

- `defaults read com.microsoft.VSCode ApplePressAndHoldEnabled` 返回 `0`。
- `mdls` 确认字体内部族名为 `FiraCode Nerd Font Mono`，与 VS Code 设置一致。
- 远程 `/home/shawn/.local/bin/yazi --version` 返回 `Yazi 26.5.6`。
- 在远程 PTY 中连续发送 100 次以上 `j` / `k` 后，Yazi 进程保持运行，chooser 文件未生成；发送 `q` 后正常以状态码 0 退出。
- VS Code 完整退出并重新打开后，需在实际 Remote SSH 窗口执行最终视觉与键盘确认。

## 6. 遗留事项

- VS Code 需要完整退出并重新打开，新的 macOS 长按设置和字体缓存才会稳定生效；窗口内 `Developer: Reload Window` 不足以替代应用重启。
