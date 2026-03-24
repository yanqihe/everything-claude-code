# 转换脚本：将 commands 目录中的文件复制到 github-commands/prompts
# 并在每个文件的 YAML frontmatter 中添加 name 和 scope 字段

param(
    [string]$SourceDir = "..\commands",
    [string]$TargetDir = ".\prompts"
)

# 转换为绝对路径
$SourceDir = Join-Path (Get-Location) $SourceDir -Resolve -ErrorAction Stop
$TargetDir = Join-Path (Get-Location) $TargetDir

# 确保目标目录存在
if (Test-Path $TargetDir) {
    # 删除目录中的所有文件
    $existingFiles = Get-ChildItem -Path $TargetDir -File
    foreach ($existingFile in $existingFiles) {
        Remove-Item $existingFile.FullName -Force
    }
} else {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}
Write-Host "目标目录已准备: $TargetDir"

# 获取源目录中的所有 .md 文件
$files = Get-ChildItem -Path $SourceDir -Filter "*.md" -File

$successCount = 0
$errorCount = 0

foreach ($file in $files) {
    try {
        # 读取文件内容
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # 获取没有扩展名的文件名作为 name
        $fileName = $file.BaseName
        
        # 检查是否以 --- 开头（有 frontmatter）
        if ($content -match "^---\s*\n") {
            # 尝试找到第二个 ---
            $endIndex = $content.IndexOf("`n---", 4)
            
            if ($endIndex -gt 0) {
                # 提取 frontmatter（去掉首尾的 ---）
                $frontmatterStart = 4  # 跳过第一个 ---\n
                $frontmatterLines = $content.Substring($frontmatterStart, $endIndex - $frontmatterStart)
                
                # 分割成行并过滤出 name 和 scope 之外的行
                $lines = $frontmatterLines -split "`n"
                $otherLines = @()
                
                foreach ($line in $lines) {
                    if ($line -notmatch "^name\s*:" -and $line -notmatch "^scope\s*:" -and $line.Trim() -ne "") {
                        $otherLines += $line
                    }
                }
                
                # 重新组合 frontmatter：只保留 name 在最前面
                $frontmatterContent = "name: $fileName"
                if ($otherLines.Count -gt 0) {
                    $frontmatterContent = $frontmatterContent + "`n" + ($otherLines -join "`n")
                }
                
                # 提取 body
                $body = $content.Substring($endIndex)
                
                # 重新组合内容
                $newContent = "---`n$frontmatterContent`n$body"
                
                # 写入目标文件
                $targetPath = Join-Path $TargetDir ($fileName + ".prompt.md")
                [System.IO.File]::WriteAllText($targetPath, $newContent, [System.Text.Encoding]::UTF8)
                
                Write-Host "✓ 已处理: $($file.Name)" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "✗ 错误: $($file.Name) - 找不到结束的 ---" -ForegroundColor Red
                $errorCount++
            }
        } else {
            # 没有 frontmatter，创建新的
            $newFrontmatter = "name: $fileName`n"
            $newContent = "---`n$newFrontmatter---`n$content"
            
            $targetPath = Join-Path $TargetDir ($fileName + ".prompt.md")
            [System.IO.File]::WriteAllText($targetPath, $newContent, [System.Text.Encoding]::UTF8)
            
            Write-Host "✓ 已创建 frontmatter: $($file.Name)" -ForegroundColor Green
            $successCount++
        }
    }
    catch {
        Write-Host "✗ 错误: $($file.Name) - $_" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host "`n处理完成: 成功 $successCount, 失败 $errorCount, 总计 $($files.Count)"
