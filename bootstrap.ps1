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
  # Single premium splash with consistent fixed-width alignment.
  $project = (Get-Location).Path
  if ($project.Length -gt 48) { $project = "…" + $project.Substring($project.Length - 47) }
  $frameWidth = 70
  function Center-Line([string]$Text) {
    if ($Text.Length -gt $frameWidth) { $Text = $Text.Substring(0, $frameWidth) }
    $left = [int][Math]::Floor(($frameWidth - $Text.Length) / 2)
    return (" " * $left) + $Text + (" " * ($frameWidth - $left - $Text.Length))
  }
  Write-Host ""
  Write-Host "  ╭──────────────────────────────────────────────────────────────────────╮" -ForegroundColor Cyan
  Write-Host ("  │" + (Center-Line "█   █               █               █   █   █     █  ") + "│") -ForegroundColor Green
  Write-Host ("  │" + (Center-Line "██ ██  ███  ████  █████  ███  █ ██  █  █        █████") + "│") -ForegroundColor Green
  Write-Host ("  │" + (Center-Line "█ █ █ █   █ █   █   █   █   █ ██  █ █ █    ██     █  ") + "│") -ForegroundColor Green
  Write-Host ("  │" + (Center-Line "█ █ █ █████ █   █   █   █   █ █     ██      █     █  ") + "│") -ForegroundColor Green
  Write-Host ("  │" + (Center-Line "█   █ █     █   █   █   █   █ █     █ █     █     █  ") + "│") -ForegroundColor Green
  Write-Host ("  │" + (Center-Line "█   █ █   █ █   █   █ █ █   █ █     █  █    █     █ █") + "│") -ForegroundColor Green
  Write-Host ("  │" + (Center-Line "█   █  ███  █   █    █   ███  █     █   █  ███     █ ") + "│") -ForegroundColor Green
  Write-Host ("  │" + (Center-Line "ORGANIC-DRIVEN DEVELOPMENT · ODD") + "│") -ForegroundColor DarkCyan
  Write-Host "  ├──────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
  Write-Host ("  │" + (Center-Line "✓  INSTALACIÓN COMPLETADA") + "│") -ForegroundColor Green
  Write-Host ("  │" + (Center-Line "Proyecto: $project") + "│")
  Write-Host ("  │" + (" " * $frameWidth) + "│") -ForegroundColor Cyan
  Write-Host ("  │" + (Center-Line "PARA COMENZAR") + "│") -ForegroundColor Green
  Write-Host ("  │" + (Center-Line "1. Define el objetivo que quieres alcanzar.") + "│")
  Write-Host ("  │" + (Center-Line "2. Describe la tarea y aporta el contexto necesario.") + "│")
  Write-Host ("  │" + (Center-Line "3. Revisa las propuestas y valida los resultados.") + "│")
  Write-Host ("  │" + (" " * $frameWidth) + "│") -ForegroundColor Cyan
  Write-Host ("  │" + (Center-Line "github.com/thewild001/MentorKit") + "│") -ForegroundColor DarkCyan
  Write-Host "  ╰──────────────────────────────────────────────────────────────────────╯" -ForegroundColor Cyan
  Write-Host ""
}
finally {
  if (Test-Path $Tmp) { Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue }
}
