param(
  [Parameter(Mandatory = $true)][string]$Url,
  [string]$OutFile = ''
)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Continue'

if (-not $OutFile) {
  $name = ([Uri]$Url).Segments[-1] -replace '[?&=]', '_'
  if (-not $name) { $name = 'github-download.bin' }
  $OutFile = Join-Path (Get-Location) $name
}

Write-Output ("目标: {0}" -f $Url)
Write-Output ("保存: {0}" -f $OutFile)
Write-Output '策略: 断点续传 + 任意错误重试 30 次 + 慢速自动断开重连'

& curl.exe -L -C - --retry 30 --retry-all-errors --retry-delay 2 --retry-max-time 3600 `
  --connect-timeout 10 --speed-limit 2048 --speed-time 30 `
  -o $OutFile $Url

if (Test-Path $OutFile) {
  $item = Get-Item $OutFile
  Write-Output ("完成: {0:N0} 字节" -f $item.Length)
  Write-Output ("SHA256: {0}" -f (Get-FileHash $OutFile -Algorithm SHA256).Hash)
} else {
  Write-Output '下载失败'
}
