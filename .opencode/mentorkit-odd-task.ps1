# Native PowerShell ODD task launcher.
param(
  [Parameter(Mandatory=$true, Position=0)][string]$Feature,
  [Parameter(Mandatory=$true, Position=1)][string]$Request
)
$ErrorActionPreference = "Stop"
$helper = Join-Path $PSScriptRoot "mentorkit.py"
if (-not (Test-Path $helper)) { throw "Falta mentorkit.py" }
$uv = Get-Command uv -ErrorAction SilentlyContinue
if (-not $uv) { $uvPath = Join-Path $HOME ".local\bin\uv.exe" } else { $uvPath = $uv.Source }
if (-not (Test-Path $uvPath) -and -not $uv) { throw "uv no disponible. Ejecuta install-mentorkit.ps1." }
& $uvPath run --python 3.12 $helper odd-task $Feature $Request
exit $LASTEXITCODE
