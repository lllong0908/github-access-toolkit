param(
  [Parameter(Mandatory = $true)][string]$Url,
  [string]$OutFile = ''
)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Continue'

# 未指定保存文件名时：优先用服务器返回的官方文件名（Content-Disposition），拿不到再退回 URL 尾段
if (-not $OutFile) {
  $name = ''
  $headers = & curl.exe -sIL --connect-timeout 10 --max-time 30 $Url 2>$null | Out-String

  $mUtf8 = [regex]::Matches($headers, "filename\*\s*=\s*UTF-8''([^;\r\n]+)")
  $mQuoted = [regex]::Matches($headers, 'filename\s*=\s*"([^"\r\n]+)"')
  $mPlain = [regex]::Matches($headers, 'filename\s*=\s*([^;\r\n"]+)')

  if ($mUtf8.Count -gt 0) {
    # RFC 5987 编码的文件名（常见于中文名文件）
    $name = [System.Uri]::UnescapeDataString((($mUtf8[$mUtf8.Count - 1].Groups[1].Value).Trim()).Trim('"'))
  } elseif ($mQuoted.Count -gt 0) {
    $name = ($mQuoted[$mQuoted.Count - 1].Groups[1].Value).Trim()
  } elseif ($mPlain.Count -gt 0) {
    $name = (($mPlain[$mPlain.Count - 1].Groups[1].Value).Trim()).Trim('"')
  }

  # 清洗非法字符，防止目录穿越
  $name = $name -replace '[\\/:*?"<>|]', '_'
  if (-not $name) {
    $name = [System.IO.Path]::GetFileName(([Uri]$Url).AbsolutePath)
    if (-not $name) { $name = 'github-download.bin' }
  }
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
