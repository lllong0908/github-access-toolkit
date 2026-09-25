# 刷新 GitHub IP 钉选（配合 1-刷新IP钉选.bat 双击使用）
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

Write-Output '开始刷新 IP 钉选（约 1~2 分钟）...'
& 'C:\Tools\GoodbyeDPI\refresh-hosts.ps1'
Write-Output ''
if (-not $NoPause) { Read-Host '完成，按回车关闭窗口' }
