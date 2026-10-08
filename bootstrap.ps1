# MentorKit — native PowerShell bootstrap for Windows.
$ErrorActionPreference = "Stop"
$Repo = "thewild001/MentorKit"
$Branch = if ($env:MENTORKIT_BRANCH) { $env:MENTORKIT_BRANCH } else { "main" }
$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("mentorkit-" + [guid]::NewGuid().ToString("N"))
$Zip = Join-Path $Tmp "repo.zip"
New-Item -ItemType Directory -Path $Tmp -Force | Out-Null
try {
  if (Test-Path ".opencode") { throw ".opencode ya existe; se evita sobrescribir configuración." }
  $url = "https://github.com/$Repo/zipball/refs/heads/$Branch"
  Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Zip
  Expand-Archive -Path $Zip -DestinationPath $Tmp -Force
  $root = Get-ChildItem $Tmp -Directory | Where-Object { Test-Path (Join-Path $_.FullName ".opencode/install-mentorkit.ps1") } | Select-Object -First 1
  if (-not $root) { throw "El release no contiene un bootstrap MentorKit válido." }
  Copy-Item (Join-Path $root.FullName ".opencode") "." -Recurse
  foreach ($f in @("AGENTS.md","CLAUDE.md")) {
    $src=Join-Path $root.FullName $f
    if (Test-Path $src) { Copy-Item $src "." -Force }
  }
  foreach ($d in @(".cursor",".claude",".agents","odd",".mentor")) {
    $src=Join-Path $root.FullName $d
    if (Test-Path $src) { Copy-Item $src "." -Recurse }
  }
  $make=Join-Path $root.FullName "Makefile"
  if (Test-Path $make) { Copy-Item $make "." -Force }
  & (Join-Path ".opencode" "install-mentorkit.ps1")
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  Write-Host ""
  Write-Host "MentorKit instalado correctamente (Windows nativo)."
  Write-Host "Abre OpenCode en este proyecto y selecciona MentorKit5.0."
}
finally {
  if (Test-Path $Tmp) { Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue }
}
