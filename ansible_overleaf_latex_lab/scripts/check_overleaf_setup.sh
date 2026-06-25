#!/usr/bin/env bash
# ==============================================================================
# DoziLab: Check ob Overleaf korrekt eingerichtet ist.
# Wird vom Playbook nach dem Setup aufgerufen.
#
# Usage: check_overleaf_setup.sh
# Gibt 0 zurück wenn alles OK, 1 wenn etwas fehlt.
# ==============================================================================
set -euo pipefail

ERRORS=0
OVERLEAF_DIR="/opt/overleaf-toolkit"

check() {
    local desc="$1"
    local result="$2"

    if [[ "$result" == "ok" ]]; then
        echo "  ✓ $desc"
    else
        echo "  ✗ $desc -> $result"
        ERRORS=$((ERRORS + 1))
    fi
}

echo "Checking Overleaf setup"

command -v docker >/dev/null 2>&1 \
    && check "Docker installiert" "ok" \
    || check "Docker installiert" "nicht gefunden"

docker info >/dev/null 2>&1 \
    && check "Docker daemon erreichbar" "ok" \
    || check "Docker daemon erreichbar" "nicht erreichbar"

[[ -d "$OVERLEAF_DIR" ]] \
    && check "Overleaf Toolkit Verzeichnis" "ok" \
    || check "Overleaf Toolkit Verzeichnis" "fehlt"

[[ -f "$OVERLEAF_DIR/config/overleaf.rc" ]] \
    && check "overleaf.rc vorhanden" "ok" \
    || check "overleaf.rc vorhanden" "fehlt"

[[ -f "$OVERLEAF_DIR/config/variables.env" ]] \
    && check "variables.env vorhanden" "ok" \
    || check "variables.env vorhanden" "fehlt"

if docker ps --format '{{.Names}}' | grep -qx 'sharelatex'; then
    check "Overleaf Container läuft" "ok"
else
    check "Overleaf Container läuft" "nicht gefunden"
fi

if docker ps --format '{{.Names}}' | grep -qx 'mongo'; then
    check "Mongo Container läuft" "ok"
else
    check "Mongo Container läuft" "nicht gefunden"
fi

if docker ps --format '{{.Names}}' | grep -qx 'redis'; then
    check "Redis Container läuft" "ok"
else
    check "Redis Container läuft" "nicht gefunden"
fi

if curl -fsS --max-time 10 http://127.0.0.1/ >/dev/null; then
    check "HTTP lokal erreichbar" "ok"
else
    check "HTTP lokal erreichbar" "keine Antwort"
fi

if [[ -f "$OVERLEAF_DIR/config/overleaf.rc" ]]; then
    if grep -q '^SIBLING_CONTAINERS_ENABLED=false$' "$OVERLEAF_DIR/config/overleaf.rc"; then
        check "Sibling Containers für CE deaktiviert" "ok"
    else
        check "Sibling Containers für CE deaktiviert" "nicht gesetzt"
    fi
fi

if [[ -f "/opt/dozilab/OVERLEAF_USERS.txt" ]]; then
    check "Overleaf User-Setup-Datei vorhanden" "ok"
else
    echo "  ! Overleaf User-Setup-Datei nicht vorhanden oder Account-Automatisierung deaktiviert"
fi

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "✓ Overleaf Setup OK"
    exit 0
else
    echo "✗ $ERRORS Fehler gefunden"
    exit 1
fi
