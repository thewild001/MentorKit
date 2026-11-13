# MentorKit - native PowerShell bootstrap for Windows.
$ErrorActionPreference = "Stop"
$Repo = "thewild001/MentorKit"
$Branch = if ($env:MENTORKIT_BRANCH) { $env:MENTORKIT_BRANCH } else { "main" }
$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("mentorkit-" + [guid]::NewGuid().ToString("N"))
$Zip = Join-Path $Tmp "repo.zip"
New-Item -ItemType Directory -Path $Tmp -Force | Out-Null
try {
  $url = "https://github.com/$Repo/zipball/refs/heads/$Branch"
  Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Zip
  Expand-Archive -Path $Zip -DestinationPath $Tmp -Force
  $root = Get-ChildItem $Tmp -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName ".opencode/install-mentorkit.ps1")
  } | Select-Object -First 1
  if (-not $root) { throw "El release no contiene un bootstrap MentorKit valido." }
  if (-not (Test-Path (Join-Path $root.FullName ".opencode/mentorkit.py"))) {
    throw ("El release de '$Branch' es anterior a este bootstrap (no incluye .opencode/mentorkit.py). " +
           "Indica una rama con la migracion ODD mediante MENTORKIT_BRANCH.")
  }

  function Show-ContextMenu {
    $icons = @(
      [string][char]0x2726, [string][char]0x25C8, [string][char]0x2318,
      [string][char]0x25C9, [string][char]0x03C0, [string][char]0x25A3
    )
    $details = @(
      "Agente CLI de Anthropic", "IA de codigo open source", "Agente de codigo OpenAI",
      "Editor de codigo con IA", "Agente extensible de terminal", "GitHub Copilot para IDE"
    )
    $utf8 = $false
    try { $utf8 = ([Console]::OutputEncoding.CodePage -eq 65001) } catch { }
    $fallbackIcons = @("*",">","#","o","p","+")
    Write-Host ""
    Write-Host "  MENTORKIT  / CONTEXTOS / CONFIGURACION" -ForegroundColor Cyan
    Write-Host "  Selecciona donde integrar MentorKit." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  +------------------------------------------------------------+" -ForegroundColor DarkGray
    for ($i=0; $i -lt $contexts.Count; $i++) {
      $icon = if ($utf8) { $icons[$i] } else { $fallbackIcons[$i] }
      $content = "{0}  {1}  {2,-18} {3}" -f ($i + 1),$icon,$labels[$i],$details[$i]
      Write-Host "  | " -NoNewline -ForegroundColor DarkGray
      Write-Host $content.PadRight(59) -NoNewline -ForegroundColor Gray
      Write-Host "|" -ForegroundColor DarkGray
    }
    Write-Host "  | " -NoNewline -ForegroundColor DarkGray
    Write-Host ("A  Instalar los seis contextos".PadRight(59)) -NoNewline -ForegroundColor Cyan
    Write-Host "|" -ForegroundColor DarkGray
    Write-Host "  +------------------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  SELECCION MULTIPLE " -NoNewline -ForegroundColor White
    Write-Host "Separa los numeros con comas  |  Enter = todos" -ForegroundColor DarkGray
  }

  $contexts = @("claude","opencode","codex","cursor","pi","vscode")
  $labels = @("Claude Code","OpenCode","Codex","Cursor","Pi","VS Code Copilot")
  $raw = $env:MENTORKIT_CONTEXTS
  if ([string]::IsNullOrWhiteSpace($raw)) {
    if ([Environment]::UserInteractive -and [Console]::IsInputRedirected -eq $false) {
      Show-ContextMenu
      $answer = Read-Host "Tu seleccion [1,3,5 / a = todos]"
      if ([string]::IsNullOrWhiteSpace($answer)) { $raw = "all" } else { $raw = $answer }
    } else {
      # Backward compatibility for non-interactive one-liners and CI.
      $raw = "all"
    }
  }
  $raw = $raw.Replace(" ","").Replace(";",",")
  if ($raw -match '^(all|a|\*)$') {
    $selected = @($contexts)
  } else {
    $selected = @()
    foreach ($token in ($raw -split "," | Where-Object { $_ -ne "" })) {
      switch ($token.ToLowerInvariant()) {
        { $_ -in @("1","claude","claude-code") } { $name="claude"; break }
        { $_ -in @("2","opencode","open-code") } { $name="opencode"; break }
        { $_ -in @("3","codex") } { $name="codex"; break }
        { $_ -in @("4","cursor") } { $name="cursor"; break }
        { $_ -in @("5","pi") } { $name="pi"; break }
        { $_ -in @("6","vscode","vs-code","copilot") } { $name="vscode"; break }
        default { throw "Contexto no valido: '$token'. Usa claude, opencode, codex, cursor, pi, vscode o all." }
      }
      if ($name -notin $selected) { $selected += $name }
    }
  }
  if ($selected.Count -eq 0) { throw "Debes seleccionar al menos un contexto." }
  if (($selected -contains "opencode") -and (Test-Path ".opencode")) {
    throw ".opencode ya existe; se evita sobrescribir configuracion existente."
  }
  Write-Host ("Contextos seleccionados: " + ($selected -join ", "))

  # Shared ODD core.
  foreach ($d in @("odd",".mentor")) {
    $src=Join-Path $root.FullName $d
    if (Test-Path $src) { Copy-Item $src "." -Recurse }
  }
  $agents=Join-Path $root.FullName "AGENTS.md"
  if (Test-Path $agents) { Copy-Item $agents "." -Force }
  if ($selected -contains "opencode") {
    $make=Join-Path $root.FullName "Makefile"
    if (Test-Path $make) { Copy-Item $make "." -Force }
  }

  if ($selected -contains "claude") {
    foreach ($f in @("CLAUDE.md",".claude")) {
      $src=Join-Path $root.FullName $f
      if (Test-Path $src) { Copy-Item $src "." -Recurse -Force }
    }
  }
  if ($selected -contains "opencode") {
    Copy-Item (Join-Path $root.FullName ".opencode") "." -Recurse
  }
  if ($selected -contains "cursor") {
    $src=Join-Path $root.FullName ".cursor"
    if (Test-Path $src) { Copy-Item $src "." -Recurse }
  }
  if (($selected -contains "codex") -or ($selected -contains "pi")) {
    $src=Join-Path $root.FullName ".agents"
    if (Test-Path $src) { Copy-Item $src "." -Recurse }
  }
  if ($selected -contains "pi") {
    $src=Join-Path $root.FullName ".pi"
    if (Test-Path $src) { Copy-Item $src "." -Recurse }
  }
  if ($selected -contains "vscode") {
    $copilotInstructions=Join-Path $root.FullName ".github/copilot-instructions.md"
    if (Test-Path $copilotInstructions) {
      New-Item -ItemType Directory -Path ".github" -Force | Out-Null
      Copy-Item $copilotInstructions ".github/" -Force
    }
    foreach ($d in @("agents","skills")) {
      $src=Join-Path $root.FullName (".github/" + $d)
      if (Test-Path $src) {
        New-Item -ItemType Directory -Path (".github/" + $d) -Force | Out-Null
        Copy-Item (Join-Path $src "*") (".github/" + $d) -Recurse -Force
      }
    }
  }

  New-Item -ItemType Directory -Path ".mentorkit" -Force | Out-Null
  @{ contexts=$selected; branch=$Branch } | ConvertTo-Json -Depth 3 | Set-Content -Encoding UTF8 ".mentorkit/install.json"

  # Only supported MCP clients selected by the user are configured.
  $mcpClients = @($selected | Where-Object { $_ -in @("claude","codex","opencode","cursor") })
  if ($selected -contains "opencode") {
    $env:MENTORKIT_MCP_CLIENTS = $mcpClients -join ","
    & (Join-Path ".opencode" "install-mentorkit.ps1")
    if ($LASTEXITCODE -ne 0) { throw "El runtime OpenCode no pudo completar la instalacion/verificacion." }
  }
  Write-Host ("Adaptadores instalados: " + ($selected -join ", "))
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
