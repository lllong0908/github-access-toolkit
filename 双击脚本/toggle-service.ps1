# 停止 / 恢复加速服务（配合 2-停止或恢复加速.bat 双击使用，双击即切换）
param([switch]$NoPause)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Continue'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
  Write-Output '需要管理员权限，正在弹出授权窗口，请在弹窗点“是”...'
  try {
    Start-Process pwsh -Verb RunAs -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath
    exit 0
  } catch {
    Write-Output ('未能获得管理员权限：' + $_.Exception.Message)
    if (-not $NoPause) { Read-Host '按回车关闭窗口' }
    exit 1
  }
}

$s = Get-Service -Name 'GoodbyeDPI-GitHub' -ErrorAction SilentlyContinue
if (-not $s) {
  Write-Output '未找到服务 GoodbyeDPI-GitHub（可能未安装，请先运行 install.ps1）。'
} elseif ($s.Status -eq 'Running') {
  Stop-Service -Name 'GoodbyeDPI-GitHub' -Force
  Write-Output '已停止加速服务。再次双击本脚本即可恢复。'
} else {
  Start-Service -Name 'GoodbyeDPI-GitHub'
  Write-Output '已启动加速服务。'
}
Get-Service -Name 'GoodbyeDPI-GitHub' -ErrorAction SilentlyContinue | Format-List Name, Status, StartType
Write-Output ''
if (-not $NoPause) { Read-Host '按回车关闭窗口' }
