# 用管理员身份的 PowerShell 运行本文件即可完全还原
Stop-Service -Name 'GoodbyeDPI-GitHub' -Force -ErrorAction SilentlyContinue
sc.exe delete 'GoodbyeDPI-GitHub' | Out-Null
Get-Process -Name 'goodbyedpi' -ErrorAction SilentlyContinue | Stop-Process -Force
Unregister-ScheduledTask -TaskName 'GitHub-Hosts-Refresh' -Confirm:$false -ErrorAction SilentlyContinue
$hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
$text = [System.IO.File]::ReadAllText($hostsPath)
$text = [regex]::Replace($text, "(?s)\r?\n?# >>> goodbyedpi-github managed block >>>.*?# <<< goodbyedpi-github managed block <<<\r?\n?", "`n")
[System.IO.File]::WriteAllText($hostsPath, $text, (New-Object System.Text.UTF8Encoding($false)))
ipconfig /flushdns | Out-Null
Write-Output '已还原 hosts、移除服务与计划任务。C:\Tools\GoodbyeDPI 目录可手动删除。'
