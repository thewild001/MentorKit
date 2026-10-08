# Native PowerShell launcher for MentorKit verification.
param([switch]$Json)
$ErrorActionPreference = "Stop"
$helper = Join-Path $PSScriptRoot "mentorkit.py"
if (-not (Test-Path $helper)) { throw "Falta mentorkit.py" }
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command py -ErrorAction SilentlyContinue }
if (-not $py) { throw "Python no está disponible." }
if ($Json) { & $py.Source $helper verify --json } else { & $py.Source $helper verify }
exit $LASTEXITCODE
