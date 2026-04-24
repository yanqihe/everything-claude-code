# deploy-to-claude.ps1 使用说明

将仓库最新配置一键发布到 `C:\Users\heyan\.claude` 的自动化脚本。

> **项目地址**: https://github.com/xiaofenghe/everything-claude-code

## 脚本位置

```
./github-using-packages/deploy-to-claude.ps1
```

## 执行步骤

| # | 操作 | 说明 |
|---|------|------|
| 1 | — | 脚本保存在 `./github-using-packages` 下 |
| 2 | `git fetch upstream` + `git rebase --onto upstream/main --root` + `git push --force origin main`（rebase 无进展时自动 fallback 到 `git merge`） | 拉取上游最新代码 → 优先 rebase 保持线性历史 → rebase 无进展时自动 merge 兜底 → 强制推送到个人仓库 |
| 3 | 执行 `convert-commands.ps1` | 将 `./commands/*.md` 转换为 `./github-using-packages/prompts/*.prompt.md` |
| 4 | 备份 `.claude` → `.claude_back` | 先删除旧备份，再全量备份当前 `.claude` |
| 5 | 清空 `.claude` | 删除 `.claude` 目录下所有文件及子目录 |
| 6 | `./agents` → `.claude/agents` | 复制所有 agent 定义文件 |
| 7 | `./github-using-packages/prompts` → `.claude/prompts` | 复制转换后的 prompt 文件 |
| 8 | `./rules` → `.claude/rules` | 复制规则文件 |
| 9 | `./skills` → `.claude/skills` | 复制所有 skill 文件 |
| 10 | `./autoresearch` → `.claude/skills/autoresearch` | 复制 autoresearch 目录到 skills 下 |
| 11 | `./examples/user-CLAUDE.md` → `.claude/CLAUDE.md` | 更新用户级 CLAUDE.md |
| 12 | 回退（任意步骤失败时） | 见下方“回退策略” |

## 回退策略

步骤 2～11 中任意一步出错或未成功完成，脚本将自动执行回退：

- **备份未创建时**（步骤 2/3 失败）：`.claude` 原目录完好，直接报错退出
- **备份已创建且已清空时**（步骤 5～11 失败）：从 `.claude_back` 完整还原 `.claude`
- **无论成败**，`.claude_back` 始终保留为最新备份，不会被删除

## 使用方法

```powershell
# 在仓库根目录运行
.\github-using-packages\deploy-to-claude.ps1

# 或进入脚本目录运行
cd github-using-packages
.\deploy-to-claude.ps1
```

## 前置条件

- PowerShell 5.1+
- 已配置 `upstream` remote（指向原始仓库）
- `git` 可在当前环境中调用

## 目标目录结构

发布成功后，`C:\Users\heyan\.claude` 的结构如下：

```
.claude/
├── CLAUDE.md                    ← 来自 ./examples/user-CLAUDE.md
├── agents/
│   └── *.md                     ← 来自 ./agents/
├── prompts/
│   └── *.prompt.md              ← 来自 ./github-using-packages/prompts/
├── rules/
│   ├── common/                  ← 来自 ./rules/common/
│   ├── typescript/              ← 来自 ./rules/typescript/
│   └── ...(其他语言规则)
└── skills/
    ├── api-design/              ← 来自 ./skills/api-design/
    ├── tdd-workflow/            ← 来自 ./skills/tdd-workflow/
    ├── ...(其他 skill 目录)
    └── autoresearch/            ← 来自 ./autoresearch/
```
