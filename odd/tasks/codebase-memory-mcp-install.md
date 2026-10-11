# codebase-memory-mcp-install

## Objective

Garantizar que el instalador de MentorKit deja `codebase-memory-mcp` instalado,
verificado y configurado para Claude Code, Codex, OpenCode y Cursor en Linux,
macOS y Windows, sin depender de `latest` ni de instaladores con efectos
secundarios (hooks, skills, edición de PATH).

## Specs

S1. Instalación del binario fijada y verificada.
- Acceptance: versión fijada (`CBM_VERSION`), SHA-256 por activo embebido en `mentorkit.py`; un hash que no coincide aborta sin instalar. Linux usa el build `portable`.
- Checks: descarga real v0.11.0 en Linux; prueba negativa con hash alterado.

S2. Configuración idempotente por agente.
- Acceptance: Claude (`~/.claude.json` → `mcpServers`), Cursor (`~/.cursor/mcp.json`), OpenCode (`opencode.json` → `mcp`), Codex (`config.toml` → `[mcp_servers.*]`). Se conserva el resto del archivo; JSON inválido nunca se sobrescribe; dos ejecuciones dan el mismo resultado.
- Checks: HOME falso con configuración previa; doble ejecución; JSON corrupto.

S3. Verificación real.
- Acceptance: `verify` hace handshake MCP por stdio (`initialize` + `tools/list`) y comprueba que cada agente apunta a un binario existente.
- Checks: ejecución local; paso en `platform-smoke.yml` (ubuntu/macos/windows).

S4. Corregir `configure_mcp` (escribía `\n` literal y corrompía `opencode.json`).
- Acceptance: el archivo resultante es JSON válido terminado en salto de línea real.

## Tasks

- [x] T1 — Descarga fijada + checksum + instalación por SO/arquitectura
  - Spec: S1
  - Route: `.opencode/mentorkit.py`
  - Commit: pending
- [x] T2 — Escritores de configuración para los cuatro agentes
  - Spec: S2, S4
  - Route: `.opencode/mentorkit.py`
  - Commit: pending
- [x] T3 — Handshake en `verify` y comando `configure-mcp`
  - Spec: S3
  - Route: `.opencode/mentorkit.py`
  - Commit: pending
- [x] T4 — CI y documentación
  - Spec: S3
  - Route: `.github/workflows/platform-smoke.yml`, `README.md`
  - Commit: pending

## Verification

- [x] S1 — descarga real v0.11.0 en Linux; hash alterado rechazado sin escribir nada
- [x] S2 — HOME falso con configuración previa; 2ª ejecución sin cambios; JSON inválido intacto
- [x] S3 — handshake real (17 herramientas) en Linux; Windows/macOS solo vía CI
- [x] S4 — `opencode.json` válido y con salto de línea real
- [x] Regressions: splash y guard de `bootstrap.sh` intactos

## Log

L1. Decisión: escribir solo las entradas MCP en vez de ejecutar el instalador oficial con `--clients`, porque este añade hooks, skills, agentes y edita `~/.profile`. Upstream no ofrece un modo solo-MCP.
L2. Limitación: Windows y macOS no se pueden ejecutar en este sandbox; solo los cubre CI.
L3. Ruta global de OpenCode: `~/.config/opencode/opencode.json` en todos los SO (respeta `XDG_CONFIG_HOME`); se actualiza además la ruta heredada si ya existe.

## Delivery

- Status: active
- Branch: claude/odd-splash
- Review candidate: claude/odd-splash
- Next step: revisar el resultado de platform-smoke en macOS y Windows
