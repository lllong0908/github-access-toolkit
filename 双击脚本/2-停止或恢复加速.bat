@echo off
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0toggle-service.ps1"
if errorlevel 1 pause
