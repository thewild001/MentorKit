# MentorKit — Makefile raíz
#
# Targets:
#   make help               mostrar esta ayuda
#   make install            crear/reparar venv (idempotente, 0.6-30s)
#   make verify             check rápido (Python + imports + versiones)
#   make clean              borrar venv (próximo install parte de cero)
#   make ci                 simular GitLab CI localmente (install + verify + assert)
#   make archive-spec       merge un spec delta a openspec/system-spec.md y archiva el original
#   make init-constitution  generar/regenerar openspec/memory/constitution.md
#   make all                alias de install

SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c

.DEFAULT_GOAL := help

.PHONY: help install verify clean ci archive-spec init-constitution all

help:  ## Mostrar esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "💡 Tips de uso con Skills Superpower:"
	@echo "  - Antes de especificar: opencode run skill brainstorming"
	@echo "  - Antes de implementar: opencode run skill verification-before-completion"
	@echo "  - Durante desarrollo: opencode run skill using-git-worktrees"
	@echo "  - En PRs: opencode run skill work-unit-commits"

install:  ## Crear/reparar venv (Python 3.12.13 + 60 deps)
	@bash .opencode/install-mentorkit.sh --fix

verify:  ## Check: Python version + 4 imports (markitdown, striprtf, graphify, uv)
	@bash .opencode/mentorkit-verify.sh

clean:  ## Borrar venv y python-path.txt (fuerza install fresh)
	@echo "  Removiendo .opencode/.mentorkit/venv/ y python-path.txt ..."
	@rm -rf .opencode/.mentorkit/venv .opencode/.mentorkit/python-path.txt
	@echo "  ✓ venv eliminado. Corre 'make install' para recrear."

ci:  ## Simular GitLab CI localmente (install + verify + JSON assert)
	@bash .opencode/install-mentorkit.sh --fix
	@bash .opencode/mentorkit-verify.sh --json | tee verify.json
	@jq -e '.python_ok and .all_deps_ok' verify.json > /dev/null || { \
		echo "❌ Garantía violada — diagnóstico:"; \
		jq '{python, target, python_ok, all_deps_ok, broken: (.deps | to_entries | map(select(.value.ok == false)) | map({key, error: .value.error}))}' verify.json; \
		exit 1; \
	}
	@echo "✅ Las 4 garantías se cumplen (igual que en CI)"

archive-spec:  ## Merge un spec a openspec/system-spec.md (SPEC=<path> [DRY_RUN=1] [FORCE=1] [COMMIT=1] [FORCE_DIRTY=1])
	@if [ -z "$(SPEC)" ]; then \
		echo "❌ Uso: make archive-spec SPEC=<path> [DRY_RUN=1] [FORCE=1] [COMMIT=1] [FORCE_DIRTY=1]"; \
		echo "   Ejemplo: make archive-spec SPEC=openspec/specs/001-foo/spec.md"; \
		echo "           make archive-spec DRY_RUN=1 SPEC=openspec/specs/001-foo/spec.md"; \
		echo "           make archive-spec COMMIT=1 SPEC=openspec/specs/001-foo/spec.md"; \
		exit 1; \
	fi
	@ROOT=$$(git rev-parse --show-toplevel 2>/dev/null) || { echo "❌ No estamos dentro de un repo git"; exit 1; }; \
	ARGS=""; \
	[ "$(DRY_RUN)"     = "1" ] && ARGS="$$ARGS --dry-run"; \
	[ "$(FORCE)"       = "1" ] && ARGS="$$ARGS --force"; \
	[ "$(COMMIT)"      = "1" ] && ARGS="$$ARGS --commit"; \
	[ "$(FORCE_DIRTY)" = "1" ] && ARGS="$$ARGS --force-dirty"; \
	bash "$$ROOT/.opencode/mentorkit-archive-spec.sh" $$ARGS "$(SPEC)"

init-constitution:  ## Generar openspec/memory/constitution.md desde template + fingerprint ([DRY_RUN=1] [FORCE=1] [NO_FINGERPRINT=1] [NO_GRAPH=1])
	@ROOT=$$(git rev-parse --show-toplevel 2>/dev/null) || { echo "❌ No estamos dentro de un repo git"; exit 1; }; \
	ARGS=""; \
	[ "$(DRY_RUN)"        = "1" ] && ARGS="$$ARGS --dry-run"; \
	[ "$(FORCE)"          = "1" ] && ARGS="$$ARGS --force"; \
	[ "$(NO_FINGERPRINT)" = "1" ] && ARGS="$$ARGS --no-fingerprint"; \
	[ "$(NO_GRAPH)"       = "1" ] && ARGS="$$ARGS --no-graph"; \
	bash "$$ROOT/.opencode/mentorkit-init-constitution.sh" $$ARGS

# sync-openspec eliminado — openspec/ es la única store (dual-path eliminado)

all: install  ## Alias de install
