@echo off
setlocal
set "PY=python"
where python >nul 2>&1 || set "PY=py"
%PY% "%~dp0mentorkit.py" fix
exit /b %ERRORLEVEL%
