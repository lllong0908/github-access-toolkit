[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Continue'

$logFile = 'C:\Tools\GoodbyeDPI\refresh.log'
if ((Test-Path $logFile) -and ((Get-Item $logFile).Length -gt 512KB)) { Remove-Item $logFile -Force }

function Log([string]$msg) {
  $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
  Write-Output $line
  Add-Content -Path $logFile -Value $line -Encoding utf8
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
  Log '错误：需要管理员权限才能写入 hosts，请以管理员身份运行（双击配套的 .cmd 会自动提权）。'
  exit 1
}

$fastly133 = @('185.199.109.133','185.199.108.133','185.199.110.133','185.199.111.133')
$fastly215 = @('185.199.109.215','185.199.108.215','185.199.110.215','185.199.111.215')
$pools = [ordered]@{
  'github.com'                    = @('20.205.243.166','20.233.83.145','20.200.245.247','20.27.177.113')
  'api.github.com'                = @('20.205.243.168','20.27.177.116','140.82.114.6','140.82.113.6')
  'codeload.github.com'           = @('20.205.243.165','20.27.177.115','140.82.113.10','140.82.112.10')
  'raw.githubusercontent.com'     = $fastly133
  'objects.githubusercontent.com' = $fastly133
  'release-assets.githubusercontent.com' = $fastly133
  'gist.githubusercontent.com'    = $fastly133
  'avatars.githubusercontent.com' = $fastly133
  'github.githubassets.com'       = $fastly215
}

Log '===== 开始刷新 GitHub 域名 IP 钉选（每个 IP 测 2 次）====='
$chosen = [ordered]@{}
foreach ($d in $pools.Keys) {
  $best = $null
  $bestScore = -1
  $bestTime = [double]::MaxValue
  foreach ($ip in $pools[$d]) {
    $ok = 0
    $sum = 0.0
    for ($k = 1; $k -le 2; $k++) {
      $out = & curl.exe -s -o NUL -w '%{http_code} %{time_total}' --connect-timeout 3 --max-time 4 --resolve ('{0}:443:{1}' -f $d, $ip) ('https://{0}/' -f $d)
      $parts = (($out | Out-String).Trim()) -split '\s+'
      $code = $parts[0]
      $t = 0.0
      [void][double]::TryParse($parts[1], [ref]$t)
      $sum += $t
      if ($code -ne '000') { $ok++ }
    }
    Log ('  测试 {0,-34} {1,-16} 通过 {2}/2 平均 {3:N2}s' -f $d, $ip, $ok, ($sum / 2))
    if (($ok -gt $bestScore) -or (($ok -eq $bestScore) -and ($ok -gt 0) -and (($sum / 2) -lt $bestTime))) {
      $bestScore = $ok
      $bestTime = $sum / 2
      $best = $ip
    }
  }
  if ($best -and $bestScore -gt 0) {
    $chosen[$d] = $best
    Log ('选定 {0} -> {1}（通过 {2}/2，平均 {3:N2}s）' -f $d, $best, $bestScore, $bestTime)
  } else {
    Log ('警告：{0} 本轮无健康 IP，不钉选（回落系统 DNS）' -f $d)
  }
}

if ($chosen.Count -gt 0) {
  $hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
  $begin = '# >>> goodbyedpi-github managed block >>>'
  $end = '# <<< goodbyedpi-github managed block <<<'
  $text = [System.IO.File]::ReadAllText($hostsPath)
  $text = [regex]::Replace($text, "(?s)\r?\n?" + [regex]::Escape($begin) + ".*?" + [regex]::Escape($end) + "\r?\n?", "`n")
  $block = $begin + "`n"
  foreach ($k in $chosen.Keys) {
    $block += ("{0}`t{1}" -f $chosen[$k], $k) + "`n"
  }
  $block += $end + "`n"
  $text = $text.TrimEnd() + "`n`n" + $block
  $isAscii = $true
  foreach ($ch in $text.ToCharArray()) { if ([int]$ch -gt 127) { $isAscii = $false; break } }
  $enc = if ($isAscii) { [System.Text.Encoding]::ASCII } else { New-Object System.Text.UTF8Encoding($false) }
  try {
    [System.IO.File]::WriteAllText($hostsPath, $text, $enc)
    & ipconfig.exe /flushdns | Out-Null
    Log ("hosts 已更新（{0} 条钉选），DNS 缓存已刷新" -f $chosen.Count)
  } catch {
    Log ("错误：写入 hosts 失败：" + $_.Exception.Message)
    exit 1
  }
} else {
  Log '本轮未找到健康 IP，hosts 保持原样'
}
Log '===== 刷新结束 ====='
