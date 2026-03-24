# convert-commands 使用说明

本文件说明如何使用 `convert-commands.ps1` 将 `commands/` 目录中的 Slash Command Markdown 文件转换为 GitHub Copilot Prompt 文件（`*.prompt.md`），并说明 frontmatter 字段处理规则。

---

## 目录结构（示例）

```
github-using-packages/
├── convert-commands.ps1   # 转换脚本（PowerShell）
├── convert-commands-usage.md  # 本使用说明
└── prompts/               # 输出目录，存放 *.prompt.md 文件
```

---

## 使用方法

在 `github-using-packages/` 目录下执行：

```powershell
.\convert-commands.ps1
```

也可以通过参数覆盖默认路径：

```powershell
.\convert-commands.ps1 `
  -SourceDir "..\commands" `
  -TargetDir ".\prompts" `
  -ZhCNDir   "..\docs\zh-CN\commands"
```

---

## 转换规则

| # | 规则说明 |
|---|----------|
| 1 | 目标文件后缀为 `*.prompt.md`，例如 `e2e.md` → `e2e.prompt.md` |
| 2 | YAML frontmatter 第一行新增 `name` 字段，值为不带扩展名的文件名 |
| 3 | `name` 字段之后新增 `description` 字段（见优先级规则） |
| 4 | 删除 YAML frontmatter 结束符（`---`）前的所有空行 |
| 5 | 仅保留 [GitHub Copilot Prompt 文件支持的 frontmatter 字段](https://code.visualstudio.com/docs/copilot/customization/prompt-files) |

### GitHub Copilot Prompt frontmatter 字段处理

GitHub Copilot Prompt 文件支持的 frontmatter 字段：`name`、`description`、`argument-hint`、`agent`、`model`、`tools`。

源文件（Claude Code 命令格式）中可能包含 GitHub Copilot 不支持的字段，脚本按以下规则处理：

| 源字段 | 操作 | 说明 |
|--------|------|------|
| `command` | **删除** | Claude Code 专用，GitHub Copilot 不支持 |
| `disable-model-invocation` | **删除** | Claude Code 专用，GitHub Copilot 不支持 |
| `allowed_tools` | **重命名为 `tools`** | GitHub Copilot 等效字段 |
| `argument-hint` | 保留 | GitHub Copilot 支持 |
| `agent` | 保留 | GitHub Copilot 支持 |
| `model` | 保留 | GitHub Copilot 支持 |
| `tools` | 保留 | GitHub Copilot 支持 |

### description 字段优先级

1. **zh-CN frontmatter** — `docs/zh-CN/commands/<name>.md` 的 `description` 值（已是中文）
2. **zh-CN H1 正文** — zh-CN 文件中 H1 标题下第一段落文字（无 frontmatter 时使用）
3. **已知翻译表** — 脚本内置的 `$KnownTranslations` 哈希表（用于尚无 zh-CN 对应文件的命令）
4. **英文 description** — 源文件 frontmatter 中的 `description` 字段（兜底，英文）
5. **英文 H1 正文** — 源文件 H1 标题下第一段落（源文件无 frontmatter 时）
6. **文件名** — 最终兜底

---

## 示例：转换目标路径说明

脚本默认将输出写入 `./prompts/`（相对于脚本所在目录），因此在 `github-using-packages/` 下运行可生成 `github-using-packages/prompts/`。

---

## 运行脚本后验证（建议）

```powershell
Get-ChildItem .\prompts -Filter "*.prompt.md" | Select-Object -First 20
Select-String -Path "commands\*.md" -Pattern "allowed_tools|command|disable-model-invocation" -SimpleMatch
```

---

如果需要我同时把 `README.MD` 删除或保留为索引文件，请告诉我。
