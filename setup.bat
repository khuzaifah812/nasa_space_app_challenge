@echo off
rem One-time setup, then start the app with the settings in .env.
cd /d "%~dp0"
if not exist .env copy .env.example .env >nul
call dart tool\setup.dart
if errorlevel 1 (pause & exit /b 1)
call flutter run --dart-define-from-file=.env %*
pause
