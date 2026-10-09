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
  # Branded success splash — shown only after the installer exits successfully.
  Write-Host ""
  Write-Host "  ╭──────────────────────────────────────────────────────────────────╮" -ForegroundColor Cyan
  Write-Host "  │                                                                  │" -ForegroundColor Cyan
  Write-Host "  │               █   █ █████ █   █ █████  ███  ████                 │" -ForegroundColor Green
  Write-Host "  │               ██ ██ █     ██  █   █   █   █ █   █                │" -ForegroundColor Green
  Write-Host "  │               █ █ █ ████  █ █ █   █   █   █ ████                 │" -ForegroundColor Green
  Write-Host "  │               █   █ █     █  ██   █   █   █ █ █                  │" -ForegroundColor Green
  Write-Host "  │               █   █ █████ █   █   █    ███  █  ██                │" -ForegroundColor Green
  Write-Host "  │             ORGANIC-DRIVEN DEVELOPMENT · ODD                    │" -ForegroundColor DarkGray
  Write-Host "  ├──────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
  Write-Host "  │  ✓  Instalación completada                                       │" -ForegroundColor Green
  Write-Host "  │  Proyecto: $((Get-Location).Path)"
  Write-Host "  │  Rama:     $Branch"
  Write-Host "  │                                                                  │"
  Write-Host "  │  PARA COMENZAR                                                   │" -ForegroundColor Green
  Write-Host "  │  1. Abre OpenCode en este proyecto.                              │"
  Write-Host "  │  2. Selecciona el agente MentorKit5.0.                           │"
  Write-Host "  │  3. Describe tu tarea; MentorKit evaluará el alcance del cambio. │"
  Write-Host "  │                                                                  │"
  Write-Host "  │  Docs: github.com/thewild001/MentorKit                           │" -ForegroundColor DarkGray
  Write-Host "  ╰──────────────────────────────────────────────────────────────────╯" -ForegroundColor Cyan
  Write-Host ""
}
finally {
  if (Test-Path $Tmp) { Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue }
}
