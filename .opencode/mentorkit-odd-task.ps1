# Native PowerShell launcher for MentorKit ODD task creation.
param(
  [Parameter(Mandatory=$true, Position=0)][string]$Feature,
  [Parameter(Mandatory=$true, Position=1)][string]$Request
)
$ErrorActionPreference = "Stop"
$helper = Join-Path $PSScriptRoot "mentorkit.py"
if (-not (Test-Path $helper)) { throw "Falta mentorkit.py" }
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command py -ErrorAction SilentlyContinue }
if (-not $py) { throw "Python no está disponible." }
& $py.Source $helper odd-task $Feature $Request
exit $LASTEXITCODE
