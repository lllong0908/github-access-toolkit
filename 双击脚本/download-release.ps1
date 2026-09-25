# 下载 GitHub Release 附件（配合 3-下载Release附件.bat 双击使用）
param(
  [string]$Url = '',
  [switch]$NoPause
)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Continue'

if (-not $Url) {
  $Url = Read-Host '请粘贴 release 下载地址后按回车'
}
if ([string]::IsNullOrWhiteSpace($Url)) {
  Write-Output '未输入地址，已退出。'
} else {
  $d = Join-Path (Split-Path -Parent $PSCommandPath) '下载'
  New-Item -ItemType Directory -Path $d -Force | Out-Null
  Set-Location $d
  Write-Output ('文件将保存到: ' + $d)
  & 'C:\Tools\GoodbyeDPI\gh-download.ps1' -Url $Url.Trim()
}
Write-Output ''
if (-not $NoPause) { Read-Host '按回车关闭窗口' }
