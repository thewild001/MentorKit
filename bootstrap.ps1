# MentorKit - native PowerShell bootstrap for Windows.
$ErrorActionPreference = "Stop"
$Repo = "thewild001/MentorKit"
$Branch = if ($env:MENTORKIT_BRANCH) { $env:MENTORKIT_BRANCH } else { "main" }
$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("mentorkit-" + [guid]::NewGuid().ToString("N"))
$Zip = Join-Path $Tmp "repo.zip"
New-Item -ItemType Directory -Path $Tmp -Force | Out-Null
try {
  if (Test-Path ".opencode") { throw ".opencode ya existe; se evita sobrescribir configuracion." }
  $url = "https://github.com/$Repo/zipball/refs/heads/$Branch"
  Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Zip
  Expand-Archive -Path $Zip -DestinationPath $Tmp -Force
  $root = Get-ChildItem $Tmp -Directory | Where-Object { Test-Path (Join-Path $_.FullName ".opencode/install-mentorkit.ps1") } | Select-Object -First 1
  if (-not $root) { throw "El release no contiene un bootstrap MentorKit valido." }
  if (-not (Test-Path (Join-Path $root.FullName ".opencode/mentorkit.py"))) {
    throw ("El release de '$Branch' es anterior a este bootstrap (no incluye .opencode/mentorkit.py). " +
           "Indica la rama que corresponde con MENTORKIT_BRANCH, por ejemplo: " +
           '$env:MENTORKIT_BRANCH="<rama>"; irm https://raw.githubusercontent.com/' + $Repo + '/<rama>/bootstrap.ps1 | iex')
  }
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
  # Single splash. Source stays ASCII (Windows PowerShell 5.1 reads BOM-less files as ANSI):
  # glyphs are built from code points, and plain ASCII is used unless the console is UTF-8.
  # Every row is measured and padded to the same inner width, so the frame always aligns.
  $W = 66
  $utf8 = $false
  try { $utf8 = ([Console]::OutputEncoding.CodePage -eq 65001) } catch { }
  if ($utf8) {
    $H = [string][char]0x2500; $V = [string][char]0x2502
    $TL = [string][char]0x256D; $TR = [string][char]0x256E; $BL = [string][char]0x2570; $BR = [string][char]0x256F
    $ML = [string][char]0x251C; $MR = [string][char]0x2524
    $OK = [string][char]0x2713; $DOT = [string][char]0xB7
    $msg = "Instalaci" + [char]0xF3 + "n completada"
  } else {
    $H = '-'; $V = '|'
    $TL = '+'; $TR = '+'; $BL = '+'; $BR = '+'; $ML = '+'; $MR = '+'
    $OK = 'OK'; $DOT = '|'
    $msg = 'Instalacion completada'
  }
  function Fit([string]$Text, [int]$Max) {
    if ($Text.Length -gt $Max) { return "..." + $Text.Substring($Text.Length - ($Max - 3)) }
    return $Text
  }
  function Rule([string]$Left, [string]$Right) {
    Write-Host ("  " + $Left + ($H * $W) + $Right) -ForegroundColor DarkGray
  }
  function Row([string]$Text = "", [string]$Color = "Gray", [switch]$Center) {
    $Text = Fit $Text ($W - 2)
    if ($Center) { $lp = [int][Math]::Floor(($W - $Text.Length) / 2) } else { $lp = 3 }
    $rp = $W - $lp - $Text.Length
    if ($rp -lt 0) { $rp = 0 }
    Write-Host ("  " + $V) -NoNewline -ForegroundColor DarkGray
    Write-Host ((" " * $lp) + $Text + (" " * $rp)) -NoNewline -ForegroundColor $Color
    Write-Host $V -ForegroundColor DarkGray
  }
  $art = @(
    ' __  __            _             _  ___ _',
    '|  \/  | ___ _ __ | |_ ___  _ __| |/ (_) |_',
    '| |\/| |/ _ \ ''_ \| __/ _ \| ''__| '' /| | __|',
    '| |  | |  __/ | | | || (_) | |  | . \| | |_',
    '|_|  |_|\___|_| |_|\__\___/|_|  |_|\_\_|\__|'
  )
  $artW = ($art | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
  $project = Fit (Get-Location).Path ($W - 18)
  $origin = Fit "$Repo @ $Branch" ($W - 18)
  Write-Host ""
  Rule $TL $TR
  Row
  foreach ($line in $art) { Row ((" " * [int][Math]::Floor(($W - $artW) / 2)) + $line.PadRight($artW)) Cyan }
  Row
  Row ("ORGANIC-DRIVEN DEVELOPMENT  $DOT  ODD") DarkCyan -Center
  Row
  Rule $ML $MR
  Row
  Row ("$OK  $msg") Green
  Row
  Row ("Origen       $origin")
  Row ("Proyecto     $project")
  Row
  Rule $ML $MR
  Row
  Row "PRIMEROS PASOS" Cyan
  Row
  Row "01  Define el objetivo que quieres alcanzar."
  Row "02  Describe la tarea y aporta el contexto necesario."
  Row "03  Revisa las propuestas y valida los resultados."
  Row
  Rule $ML $MR
  Row ("Repositorio  github.com/$Repo") DarkCyan
  Rule $BL $BR
  Write-Host ""
}
finally {
  if (Test-Path $Tmp) { Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue }
}
