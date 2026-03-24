# GitHub Commands

这个目录包含转换为 GitHub Copilot prompt 格式的命令集合。

## 目录结构

```
github-commands/
├── prompts/              # 转换后的命令 prompt 文件
├── convert-commands.ps1  # 转换脚本（PowerShell）
└── README.md            # 本文件
```

## 概述

`prompts/` 目录包含从 ECC（Everything Claude Code）项目中的 `commands/` 目录转换而来的 60 个命令文件。每个文件都按照 GitHub Copilot 的规范格式化，包含：

- **YAML Frontmatter**：包含元数据字段
  - `name`: 命令名称（不带扩展名）
  - `scope`: 作用域（设为 `user`）
  - `description`: 命令描述
- **内容**：详细的命令说明、使用场景和执行步骤

## 转换脚本

### convert-commands.ps1

这是一个 PowerShell 脚本，用于：

1. **自动复制** `../commands/` 目录下的所有 Markdown 文件到 `./prompts/` 目录
2. **添加元数据**：
   - 为每个文件添加 `name` 字段（基于文件名）
   - 为每个文件添加 `scope: user` 字段
3. **处理两种情况**：
   - 有 YAML frontmatter 的文件：在其中插入新字段
   - 没有 YAML frontmatter 的文件：创建新的 frontmatter

### 如何运行

```powershell
# 在 github-commands 目录下运行
powershell -ExecutionPolicy Bypass -File .\convert-commands.ps1
```

或通过参数指定源目录和目标目录：

```powershell
powershell -ExecutionPolicy Bypass -File .\convert-commands.ps1 -SourceDir "..\commands" -TargetDir ".\prompts"
```

### 脚本输出

脚本运行完成后会显示处理统计：
- ✓ 已处理：成功转换的文件
- ✓ 已创建 frontmatter：为没有 YAML frontmatter 的文件创建的文件
- 处理完成统计：总成功数、失败数和总文件数

## 命令列表

prompts 目录包含以下命令（共 60 个）：

| # | 命令名称 | 说明 |
|---|---------|------|
| 1 | aside | 另行讨论 |
| 2 | build-fix | 增量修复构建和类型错误 |
| 3 | checkpoint | 检查点管理 |
| 4 | claw | Claw REPL |
| 5 | code-review | 代码审查 |
| 6 | context-budget | 上下文预算分析 |
| 7 | cpp-build | C++ 构建修复 |
| 8 | cpp-review | C++ 代码审查 |
| 9 | cpp-test | C++ 测试 |
| 10 | devfleet | Claude DevFleet 多代理编排 |
| 11 | docs | 文档更新 |
| 12 | e2e | 端到端测试 |
| 13 | eval | 评估框架 |
| 14 | evolve | 演变和优化 |
| 15 | go-build | Go 构建修复 |
| 16 | go-review | Go 代码审查 |
| 17 | go-test | Go 测试 |
| 18 | gradle-build | Gradle 构建修复 |
| 19 | harness-audit | 测试框架审计 |
| 20 | instinct-export | 导出 instinct |
| 21 | instinct-import | 导入 instinct |
| 22 | instinct-status | Instinct 状态 |
| 23 | kotlin-build | Kotlin 构建修复 |
| 24 | kotlin-review | Kotlin 代码审查 |
| 25 | kotlin-test | Kotlin 测试 |
| 26 | learn-eval | 学习评估 |
| 27 | learn | 从会话中学习 |
| 28 | loop-start | 启动自主循环 |
| 29 | loop-status | 循环状态 |
| 30 | model-route | 模型路由 |
| 31 | multi-backend | 多代理后端编排 |
| 32 | multi-execute | 多代理并行执行 |
| 33 | multi-frontend | 多代理前端编排 |
| 34 | multi-plan | 多代理计划 |
| 35 | multi-workflow | 多代理工作流 |
| 36 | orchestrate | 代理编排 |
| 37 | plan | 实现计划 |
| 38 | pm2 | PM2 进程管理 |
| 39 | projects | 项目管理 |
| 40 | promote | 提升（晋升）|
| 41 | prompt-optimize | Prompt 优化 |
| 42 | prune | 清理代码 |
| 43 | python-review | Python 代码审查 |
| 44 | quality-gate | 质量检查门 |
| 45 | refactor-clean | 重构清理 |
| 46 | resume-session | 恢复会话 |
| 47 | rules-distill | 规则提炼 |
| 48 | rust-build | Rust 构建修复 |
| 49 | rust-review | Rust 代码审查 |
| 50 | rust-test | Rust 测试 |
| 51 | save-session | 保存会话 |
| 52 | sessions | 会话管理 |
| 53 | setup-pm | PM 设置 |
| 54 | skill-create | 创建技能 |
| 55 | skill-health | 技能健康检查 |
| 56 | tdd | 测试驱动开发 |
| 57 | test-coverage | 测试覆盖率 |
| 58 | update-codemaps | 更新代码地图 |
| 59 | update-docs | 更新文档 |
| 60 | verify | 验证 |

## 文件格式示例

```yaml
---
name: plan
scope: user
description: Restate requirements, assess risks, and create step-by-step implementation plan. WAIT for user CONFIRM before touching any code.
---

# Plan Command

This command invokes the **planner** agent to create a comprehensive implementation plan before writing any code.
...
```

## 处理统计

最后一次转换结果：
- 成功处理：60 个文件
- 失败数：0 个
- 总计：60 个文件

## 后续步骤

这些转换后的命令文件可以：

1. **导入到 GitHub Copilot**：用于自定义 Copilot 的行为
2. **用于提示工程**：作为高质量 prompt 的参考
3. **集成到工作流**：通过 GitHub Actions 或其他自动化工具
4. **版本控制**：跟踪命令的发展和更新

## 许可证

文件来自 [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) 项目，遵循原项目的许可证。

## 相关资源

- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) - 源项目
- 原始命令目录：`../commands/`
- 转换脚本：`./convert-commands.ps1`
