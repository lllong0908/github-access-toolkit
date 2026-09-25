@echo off
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0download-release.ps1"
if errorlevel 1 pause
