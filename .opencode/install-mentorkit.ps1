# MentorKit — native PowerShell installer (Windows).
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Helper = Join-Path $ScriptDir "mentorkit.py"
if (-not (Test-Path $Helper)) { throw "Falta .opencode/mentorkit.py" }
$uv = Get-Command uv -ErrorAction SilentlyContinue
if (-not $uv) {
  Write-Host "uv no encontrado; instalando desde el instalador oficial..."
  $env:UV_NO_MODIFY_PATH = "1"
  Invoke-Expression (Invoke-RestMethod https://astral.sh/uv/install.ps1)
  $uv = Get-Command uv -ErrorAction SilentlyContinue
}
if (-not $uv) {
  $candidate = Join-Path $HOME ".local\bin\uv.exe"
  if (Test-Path $candidate) { $uvPath = $candidate }
  else { throw "No se pudo obtener uv. Instálalo desde https://docs.astral.sh/uv/" }
} else { $uvPath = $uv.Source }
& $uvPath run --python 3.12 $Helper fix
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "MentorKit instalado/verificado correctamente."
