# MentorKit native PowerShell installer (Windows PowerShell 5.1 / PowerShell 7+).
$ErrorActionPreference = "Stop"
$Repo = "thewild001/MentorKit"
$Branch = if ($env:MENTORKIT_BRANCH) { $env:MENTORKIT_BRANCH } else { "main" }
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PythonHelper = Join-Path $ScriptDir "mentorkit.py"

if (-not (Test-Path $PythonHelper)) {
  throw "Falta .opencode/mentorkit.py"
}

$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command py -ErrorAction SilentlyContinue }
if (-not $py) { throw "Python no está instalado. Instala Python 3.10+ o usa bootstrap.ps1, que prepara el runtime." }

& $py.Source $PythonHelper fix
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "MentorKit instalado/verificado correctamente."
