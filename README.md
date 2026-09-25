# GitHub Access Toolkit

让 Windows 随时稳定访问 GitHub（网页 / `git clone` / release 附件下载）的轻量工具箱。
常驻内存约 6 MB，**只处理 GitHub 域名，其他程序联网完全不受影响**。

## 原理（三层配合）

| 层 | 作用 |
|---|---|
| **hosts 智能钉选** | 把 GitHub 各域名钉到实测健康的 IP，避开 DNS 轮询到的失效节点（这是"时好时坏"的主因） |
| **GoodbyeDPI 白名单模式** | 以 Windows 服务常驻，仅对 19 个 GitHub 域名做 DPI 绕过（`-5 --blacklist`），遇到 SNI 阻断时自动生效，平时无感 |
| **定时自愈任务** | 计划任务每 30 分钟测速并重写钉选（IP 池约 20 分钟翻转一轮），开机自动执行 |

## 环境要求

- Windows 10 / 11，PowerShell 7（`pwsh`）
- 管理员权限（安装服务与修改 hosts 需要，会弹 UAC）

## 安装

```powershell
# 管理员 PowerShell
cd github-access-toolkit
.\install.ps1
```

脚本会自动：下载 GoodbyeDPI 官方发布包（`ValdikSS/GoodbyeDPI`，GPLv3）→ 部署到 `C:\Tools\GoodbyeDPI` → 写入 hosts 钉选 → 注册服务 `GoodbyeDPI-GitHub`（开机自启、崩溃自动重启）→ 注册计划任务 `GitHub-Hosts-Refresh`。

## 日常使用

```powershell
# 网页 / 克隆卡顿时，手动刷新 IP 钉选
pwsh -File C:\Tools\GoodbyeDPI\refresh-hosts.ps1

# 临时停止 / 恢复加速
Stop-Service GoodbyeDPI-GitHub
Start-Service GoodbyeDPI-GitHub

# 大文件下载（断点续传 + 任意错误自动重试）
pwsh -File C:\Tools\GoodbyeDPI\gh-download.ps1 -Url <release下载地址>
```

## 卸载

管理员 PowerShell 运行 `C:\Tools\GoodbyeDPI\uninstall.ps1`，一键还原 hosts、删除服务与计划任务。

## 已知局限

- 网络层偶发约 19 秒"连接重置"（网页/克隆/下载均可能撞上），重试一次即恢复；此现象与本工具无关（A/B 对照验证过开关服务失败率一致）
- release 下载速度随链路波动（实测 20~280 KB/s），不追求速度时用 `gh-download.ps1` 保证最终下完
- hosts 钉选由计划任务维护；若 GitHub 更换 IP 段导致候选池失效，更新 `refresh-hosts.ps1` 中的 `$pools` 即可

## 致谢

- [GoodbyeDPI](https://github.com/ValdikSS/GoodbyeDPI) by ValdikSS（DPI 绕过内核，GPLv3）
- 本仓库的脚本可自由使用，仅供网络调试与学习用途
