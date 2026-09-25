@echo off
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0refresh-ip.ps1"
if errorlevel 1 pause
