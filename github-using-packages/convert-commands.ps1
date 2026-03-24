# convert-commands.ps1
# Rules:
#   1. Target suffix: *.prompt.md  (e.g. e2e.md -> e2e.prompt.md)
#   2. Add "name" as first YAML frontmatter field
#   3. Add "description" after name:
#        a. zh-CN frontmatter description   (preferred)
#        b. zh-CN H1 body text              (already Chinese)
#        c. source frontmatter description  (English - KnownTranslations or use as-is)
#        d. source H1 body text             (English fallback)
#        e. filename                        (last resort)
#   4. No blank lines between last frontmatter field and closing ---
#   5. GitHub Copilot Prompt supported fields: name, description, argument-hint, agent, model, tools
#      - Removed (unsupported): command, disable-model-invocation
#      - Renamed: allowed_tools -> tools
#      - Kept as-is: argument-hint, agent, model, tools

param(
    [string]$SourceDir = "..\commands",
    [string]$TargetDir = ".\prompts",
    [string]$ZhCNDir   = "..\docs\zh-CN\commands"
)

# Known Chinese translations for commands with no zh-CN counterpart
$KnownTranslations = @{
    "prune" = "删除超过 30 天且从未升级的待处理本能"
}

function Get-FrontmatterField([string]$Content, [string]$Field) {
    if ($Content -match "(?m)^$Field\s*:\s*[`"']?(.+?)[`"']?\s*$") {
        return $Matches[1].Trim()
    }
    return $null
}

# Fields not supported by GitHub Copilot Prompt files — will be silently dropped
$UnsupportedFields = @("command", "disable-model-invocation")
# Fields renamed for GitHub Copilot Prompt files
$RenameFields = @{ "allowed_tools" = "tools" }

function Get-OtherFrontmatterLines([string]$Content, [string[]]$ExcludeFields) {
    if ($Content -notmatch "^---") { return @() }
    # Normalise line endings
    $norm = $Content -replace "`r`n", "`n"
    $firstEnd = $norm.IndexOf("`n---", 3)
    if ($firstEnd -lt 0) { return @() }
    $fmText = $norm.Substring(4, $firstEnd - 4)
    $lines  = $fmText -split "`n"
    $result = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -eq "") { continue }
        # Skip excluded fields (name, description already handled)
        $skip = $false
        foreach ($field in $ExcludeFields) {
            if ($trimmed -match "^$field\s*:") { $skip = $true; break }
        }
        if ($skip) { continue }
        # Skip unsupported GitHub Copilot Prompt fields
        $unsupported = $false
        foreach ($field in $script:UnsupportedFields) {
            if ($trimmed -match "^$field\s*:") { $unsupported = $true; break }
        }
        if ($unsupported) { continue }
        # Rename fields (e.g. allowed_tools -> tools)
        foreach ($oldKey in $script:RenameFields.Keys) {
            if ($trimmed -match "^$oldKey\s*:") {
                $trimmed = $trimmed -replace "^$oldKey\s*:", ($script:RenameFields[$oldKey] + ":")
                break
            }
        }
        $result.Add($trimmed)
    }
    return $result
}

function Get-BodyAfterFrontmatter([string]$Content) {
    if ($Content -notmatch "^---") { return $Content }
    $norm     = $Content -replace "`r`n", "`n"
    $firstEnd = $norm.IndexOf("`n---", 3)
    if ($firstEnd -lt 0) { return $norm }
    # Skip past the closing --- line (including its trailing newline if present)
    $afterClose = $norm.Substring($firstEnd + 4)   # skip \n---
    $afterClose = $afterClose -replace "^`n", ""   # skip the \n after ---
    return $afterClose
}

function Get-H1BodySummary([string]$Content) {
    $norm = $Content -replace "`r`n", "`n"
    $body = $norm -replace "(?s)^---.*?`n---`n?", ""
    if ($body -match "(?ms)^# .+?`n+([\s\S]+?)(`n`n|`n##|\z)") {
        $para = $Matches[1] -replace "\*\*|__|\*|_|#+\s", ""
        $para = ($para.Trim() -replace "`n", " ")
        return $para.Substring(0, [Math]::Min(150, $para.Length))
    }
    return $null
}

# ── Resolve absolute paths ─────────────────────────────────────────────────
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceDir  = [System.IO.Path]::GetFullPath((Join-Path $ScriptRoot $SourceDir))
$TargetDir  = [System.IO.Path]::GetFullPath((Join-Path $ScriptRoot $TargetDir))
$ZhCNDir    = [System.IO.Path]::GetFullPath((Join-Path $ScriptRoot $ZhCNDir))

Write-Host "Source : $SourceDir"
Write-Host "Target : $TargetDir"
Write-Host "ZhCN   : $ZhCNDir"
Write-Host ""

if (Test-Path $TargetDir) {
    Get-ChildItem -Path $TargetDir -Filter "*.prompt.md" -File |
        ForEach-Object { Remove-Item $_.FullName -Force }
} else {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

$files        = Get-ChildItem -Path $SourceDir -Filter "*.md" -File
$successCount = 0
$errorCount   = 0
$utf8NoBom    = [System.Text.UTF8Encoding]::new($false)

foreach ($file in $files) {
    try {
        $name      = $file.BaseName
        $content   = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
        $zhContent = $null
        $zhFile    = Join-Path $ZhCNDir "$name.md"
        if (Test-Path $zhFile) {
            $zhContent = [System.IO.File]::ReadAllText($zhFile, [System.Text.Encoding]::UTF8)
        }

        # ── Resolve description ─────────────────────────────────────────────
        $description = $null
        $descSource  = ""

        if ($zhContent) {
            $description = Get-FrontmatterField $zhContent "description"
            if ($description) { $descSource = "zh-CN frontmatter" }
        }

        if (-not $description -and $zhContent) {
            $description = Get-H1BodySummary $zhContent
            if ($description) { $descSource = "zh-CN H1 body" }
        }

        if (-not $description -and $KnownTranslations.ContainsKey($name)) {
            $description = $KnownTranslations[$name]
            $descSource  = "known translation"
        }

        if (-not $description) {
            $description = Get-FrontmatterField $content "description"
            if ($description) {
                $descSource = "English description"
                Write-Host "  WARN $name : using English description (no zh-CN)" -ForegroundColor Yellow
            }
        }

        if (-not $description) {
            $description = Get-H1BodySummary $content
            if ($description) {
                $descSource = "English H1 body"
                Write-Host "  WARN $name : extracted from English H1 body" -ForegroundColor Yellow
            }
        }

        if (-not $description) {
            $description = $name
            $descSource  = "filename fallback"
            Write-Host "  WARN $name : description fell back to filename" -ForegroundColor Yellow
        }

        # ── Other frontmatter fields (supported by GitHub Copilot Prompt) ──
        $otherLines = Get-OtherFrontmatterLines $content @("name", "description")

        # ── Build new frontmatter (no blank lines before closing ---) ───────
        $fmLines = [System.Collections.Generic.List[string]]::new()
        $fmLines.Add("name: $name")
        $fmLines.Add("description: $description")
        foreach ($l in $otherLines) { $fmLines.Add($l) }
        $frontmatter = "---`n" + ($fmLines -join "`n") + "`n---"

        # ── Extract body (LF-normalised, leading blank lines stripped) ──────
        $body = Get-BodyAfterFrontmatter $content
        # Trim any remaining leading blank lines from body
        $body = $body -replace "^(`n)+", ""

        # ── Assemble: frontmatter, blank line, then body ─────────────────────
        $newContent = $frontmatter + "`n`n" + $body

        # ── Write target ────────────────────────────────────────────────────
        $targetPath = Join-Path $TargetDir ($name + ".prompt.md")
        [System.IO.File]::WriteAllText($targetPath, $newContent, $utf8NoBom)

        Write-Host "OK  $name  [$descSource]" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host "ERR $($file.Name) - $_" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""
Write-Host "Done: $successCount OK, $errorCount failed, $($files.Count) total"