# ============================================================
#  GitHub Access Toolkit - 一键安装（需管理员权限）
#  用法：管理员 PowerShell 中执行  .\install.ps1
# ============================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Continue'

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
  Write-Output '请以管理员身份运行本脚本（右键 PowerShell -> 以管理员身份运行）。'
  exit 1
}

$toolDir = 'C:\Tools\GoodbyeDPI'
$ver = '0.2.2'
$zipUrl = "https://github.com/ValdikSS/GoodbyeDPI/releases/download/$ver/goodbyedpi-$ver.zip"

Write-Output '=== 1. 下载 GoodbyeDPI 官方发布包 ==='
$zip = Join-Path $env:TEMP "goodbyedpi-$ver.zip"
& curl.exe -L --retry 5 --retry-all-errors -o $zip $zipUrl
if (-not ((Test-Path $zip) -and ((Get-Item $zip).Length -gt 100000))) {
  Write-Output '下载失败，请检查网络后重试。'
  exit 1
}
Write-Output ("已下载 {0:N0} 字节" -f (Get-Item $zip).Length)

Write-Output ''
Write-Output '=== 2. 部署到 C:\Tools\GoodbyeDPI ==='
$tmp = Join-Path $env:TEMP 'goodbyedpi-extract'
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
Expand-Archive -Path $zip -DestinationPath $tmp -Force
$inner = Get-ChildItem $tmp -Directory | Select-Object -First 1
if (-not $inner) { Write-Output '解压失败。'; exit 1 }
New-Item -ItemType Directory -Path $toolDir -Force | Out-Null
Copy-Item -Path (Join-Path $inner.FullName '*') -Destination $toolDir -Recurse -Force
foreach ($f in @('refresh-hosts.ps1', 'gh-download.ps1', 'uninstall.ps1', 'github-domains.txt')) {
  Copy-Item (Join-Path $PSScriptRoot $f) (Join-Path $toolDir $f) -Force
}
Write-Output '文件就位。'

Write-Output ''
Write-Output '=== 3. hosts 智能钉选（实测最快 IP）==='
& pwsh.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $toolDir 'refresh-hosts.ps1')

Write-Output ''
Write-Output '=== 4. 注册 Windows 服务 GoodbyeDPI-GitHub ==='
$binPath = Join-Path $toolDir 'x86_64\goodbyedpi.exe'
$blacklist = Join-Path $toolDir 'github-domains.txt'
Get-Service -Name 'GoodbyeDPI-GitHub' -ErrorAction SilentlyContinue | ForEach-Object {
  if ($_.Status -eq 'Running') { Stop-Service -Name 'GoodbyeDPI-GitHub' -Force -ErrorAction SilentlyContinue }
}
& sc.exe delete 'GoodbyeDPI-GitHub' 2>$null | Out-Null
Start-Sleep -Seconds 1
New-Service -Name 'GoodbyeDPI-GitHub' `
  -BinaryPathName ('"{0}" -5 --blacklist "{1}"' -f $binPath, $blacklist) `
  -DisplayName 'GoodbyeDPI GitHub 加速' `
  -Description '仅对 GitHub 域名白名单做 DPI 绕过，不影响其他程序联网' `
  -StartupType Automatic | Out-Null
& sc.exe failure 'GoodbyeDPI-GitHub' reset= 86400 actions= restart/5000/restart/15000/restart/60000 | Out-Null
Start-Service -Name 'GoodbyeDPI-GitHub' -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

Write-Output ''
Write-Output '=== 5. 注册计划任务 GitHub-Hosts-Refresh（每 30 分钟自愈）==='
$action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File "C:\Tools\GoodbyeDPI\refresh-hosts.ps1"'
$tr1 = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(30) -RepetitionInterval (New-TimeSpan -Minutes 30)
$tr2 = New-ScheduledTaskTrigger -Daily -At 09:00
$tr3 = New-ScheduledTaskTrigger -AtStartup
$pr = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$st = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 15)
Register-ScheduledTask -TaskName 'GitHub-Hosts-Refresh' -Action $action -Trigger @($tr1, $tr2, $tr3) -Principal $pr -Settings $st -Force | Out-Null

Write-Output ''
Write-Output '=== 6. 安装完成，当前状态 ==='
Get-Service -Name 'GoodbyeDPI-GitHub' | ForEach-Object {
  Write-Output ("服务: {0} [{1}] 启动类型={2}" -f $_.Name, $_.Status, $_.StartType)
}
Get-Process -Name 'goodbyedpi' -ErrorAction SilentlyContinue | ForEach-Object {
  Write-Output ("进程: 常驻内存 {0:N1} MB" -f ($_.WorkingSet64 / 1MB))
}
Get-ScheduledTask -TaskName 'GitHub-Hosts-Refresh' | ForEach-Object {
  Write-Output ("计划任务: {0} [{1}]" -f $_.TaskName, $_.State)
}
