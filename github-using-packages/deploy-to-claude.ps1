# deploy-to-claude.ps1
# 将最新配置发布到 C:\Users\heyan\.claude
#
# 执行步骤：
#   1. git merge upstream/main 获取最新代码
#   2. 执行 convert-commands.ps1 生成 prompts
#   3. 备份 .claude → .claude_back
#   4. 清空 .claude 目录
#   5. 复制 agents / prompts / rules / skills / autoresearch / user-CLAUDE.md
#
# 回退策略（步骤 2~11 任意失败）：
#   - 若备份已创建且 .claude 已被清空，从 .claude_back 还原 .claude
#   - 无论成败均保留 .claude_back（最新备份）

#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── 路径常量 ───────────────────────────────────────────────────────────────────
$ScriptDir = $PSScriptRoot
$RepoRoot  = Split-Path -Parent $ScriptDir

$ClaudeDir = "C:\Users\heyan\.claude"
$BackupDir = "C:\Users\heyan\.claude_back"

# ── 状态标志（用于回退判断） ────────────────────────────────────────────────────
$script:BackupCreated = $false
$script:ClaudeCleared = $false

# ─────────────────────────────────────────────────────────────────────────────
# 工具函数
# ─────────────────────────────────────────────────────────────────────────────

function Write-Step {
    param([int]$Number, [string]$Message)
    Write-Host ""
    Write-Host "[$Number] $Message" -ForegroundColor Cyan
}

function Write-Ok   { param([string]$Msg) Write-Host "    OK  $Msg" -ForegroundColor Green  }
function Write-Warn { param([string]$Msg) Write-Host "    WARN $Msg" -ForegroundColor Yellow }
function Write-Err  { param([string]$Msg) Write-Host "    ERR  $Msg" -ForegroundColor Red    }

# 执行 git 命令，失败时最多重试一次（处理网络抖动）
function Invoke-Git {
    param([string[]]$GitArgs, [switch]$NoRetry)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0 -and -not $NoRetry) {
        # 网络类错误重试一次
        & git @GitArgs
        if ($LASTEXITCODE -ne 0) {
            throw "git $($GitArgs -join ' ') 失败，退出码: $LASTEXITCODE"
        }
    } elseif ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') 失败，退出码: $LASTEXITCODE"
    }
}

# 回退函数：还原 .claude，保留备份
function Invoke-Rollback {
    param([string]$Reason)

    Write-Host ""
    Write-Err "部署失败: $Reason"
    Write-Host ""
    Write-Host "正在执行回退..." -ForegroundColor Yellow

    try {
        if ($script:BackupCreated) {
            if ($script:ClaudeCleared) {
                # .claude 已被清空或部分写入，从备份还原
                if (Test-Path $ClaudeDir) {
                    Remove-Item -Path $ClaudeDir -Recurse -Force
                }
                Copy-Item -Path $BackupDir -Destination $ClaudeDir -Recurse -Force
                Write-Ok ".claude 已从备份还原"
            } else {
                Write-Ok ".claude 未被修改，原目录完好"
            }
            Write-Host "    备份保留于: $BackupDir" -ForegroundColor Cyan
        } else {
            Write-Ok "备份尚未创建，.claude 原目录完好"
        }
    } catch {
        Write-Err "回退过程出错: $($_.Exception.Message)"
        Write-Err "请手动从 $BackupDir 还原 .claude"
    }

    Write-Host ""
    exit 1
}

# ─────────────────────────────────────────────────────────────────────────────
# 主流程
# ─────────────────────────────────────────────────────────────────────────────

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  deploy-to-claude.ps1  —  配置发布脚本"            -ForegroundColor Magenta
Write-Host "  RepoRoot : $RepoRoot"                               -ForegroundColor DarkGray
Write-Host "  目标目录 : $ClaudeDir"                              -ForegroundColor DarkGray
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Magenta

try {

    # ── 步骤 2：git fetch upstream + rebase + force push ──────────────────────
    Write-Step 2 "同步上游: git fetch upstream && git rebase upstream/main && git push --force origin main"
    Push-Location $RepoRoot
    try {
        Invoke-Git "fetch", "upstream"
        Invoke-Git "rebase", "upstream/main"
        Invoke-Git "push", "--force", "origin", "main"
    } finally {
        Pop-Location
    }
    Write-Ok "rebase + force push 完成"

    # ── 步骤 3：执行 convert-commands.ps1 ────────────────────────────────────
    Write-Step 3 "执行 convert-commands.ps1"
    $convertScript = Join-Path $ScriptDir "convert-commands.ps1"
    if (-not (Test-Path $convertScript)) {
        throw "未找到 convert-commands.ps1: $convertScript"
    }
    & $convertScript
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "convert-commands.ps1 以退出码 $LASTEXITCODE 结束"
    }
    Write-Ok "convert-commands.ps1 执行完成"

    # ── 步骤 4：备份 .claude → .claude_back ──────────────────────────────────
    Write-Step 4 "备份 .claude → .claude_back"
    if (Test-Path $ClaudeDir) {
        # 先清除旧备份
        if (Test-Path $BackupDir) {
            Remove-Item -Path $BackupDir -Recurse -Force
        }
        Copy-Item -Path $ClaudeDir -Destination $BackupDir -Recurse -Force
        $script:BackupCreated = $true
        Write-Ok "备份已创建: $BackupDir"
    } else {
        Write-Warn ".claude 目录不存在，跳过备份，将创建新目录"
        New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
    }

    # ── 步骤 5：清空 .claude ──────────────────────────────────────────────────
    Write-Step 5 "清空 .claude 目录"
    Get-ChildItem -Path $ClaudeDir -Force |
        Remove-Item -Recurse -Force
    $script:ClaudeCleared = $true
    Write-Ok ".claude 目录已清空"

    # ── 步骤 6：复制 agents ───────────────────────────────────────────────────
    Write-Step 6 "复制 ./agents → .claude/agents"
    $srcAgents = Join-Path $RepoRoot "agents"
    if (-not (Test-Path $srcAgents)) {
        throw "源目录不存在: $srcAgents"
    }
    Copy-Item -Path $srcAgents -Destination (Join-Path $ClaudeDir "agents") -Recurse -Force
    Write-Ok "agents 复制完成"

    # ── 步骤 7：复制 prompts ──────────────────────────────────────────────────
    Write-Step 7 "复制 ./github-using-packages/prompts → .claude/prompts"
    $srcPrompts = Join-Path $ScriptDir "prompts"
    if (-not (Test-Path $srcPrompts)) {
        throw "源目录不存在: $srcPrompts"
    }
    Copy-Item -Path $srcPrompts -Destination (Join-Path $ClaudeDir "prompts") -Recurse -Force
    Write-Ok "prompts 复制完成"

    # ── 步骤 8：复制 rules → .claude/rules ──────────────────────────────────
    Write-Step 8 "复制 ./rules → .claude/rules"
    $srcRules = Join-Path $RepoRoot "rules"
    if (-not (Test-Path $srcRules)) {
        throw "源目录不存在: $srcRules"
    }
    Copy-Item -Path $srcRules -Destination (Join-Path $ClaudeDir "rules") -Recurse -Force
    Write-Ok "rules 复制完成"

    # ── 步骤 9：复制 skills → .claude/skills ─────────────────────────────────
    Write-Step 9 "复制 ./skills → .claude/skills"
    $srcSkills = Join-Path $RepoRoot "skills"
    if (-not (Test-Path $srcSkills)) {
        throw "源目录不存在: $srcSkills"
    }
    Copy-Item -Path $srcSkills -Destination (Join-Path $ClaudeDir "skills") -Recurse -Force
    Write-Ok "skills 复制完成"

    # ── 步骤 10：复制 autoresearch → skills/autoresearch ──────────────────────
    Write-Step 10 "复制 ./autoresearch → .claude/skills/autoresearch"
    $srcAutoresearch = Join-Path $RepoRoot "autoresearch"
    if (-not (Test-Path $srcAutoresearch)) {
        throw "源目录不存在: $srcAutoresearch"
    }
    Copy-Item -Path $srcAutoresearch -Destination (Join-Path $ClaudeDir "skills\autoresearch") -Recurse -Force
    Write-Ok "autoresearch 复制完成"

    # ── 步骤 11：复制 user-CLAUDE.md → CLAUDE.md ─────────────────────────────
    Write-Step 11 "复制 ./examples/user-CLAUDE.md → .claude/CLAUDE.md"
    $srcClaude = Join-Path $RepoRoot "examples\user-CLAUDE.md"
    if (-not (Test-Path $srcClaude)) {
        throw "源文件不存在: $srcClaude"
    }
    Copy-Item -Path $srcClaude -Destination (Join-Path $ClaudeDir "CLAUDE.md") -Force
    Write-Ok "CLAUDE.md 复制完成"

    # ── 完成 ──────────────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  部署成功！"                                         -ForegroundColor Green
    Write-Host "  目标目录 : $ClaudeDir"                              -ForegroundColor Green
    Write-Host "  备份目录 : $BackupDir"                              -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green

} catch {
    Invoke-Rollback -Reason $_.Exception.Message
}
