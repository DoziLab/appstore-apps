#!/usr/bin/env bash
# ==============================================================================
# DoziLab: Check ob ein Student-Account korrekt eingerichtet ist.
# Wird vom Playbook nach dem Setup aufgerufen.
#
# Usage: check_student_setup.sh <username> [workdir]
# Gibt 0 zurück wenn alles OK, 1 wenn etwas fehlt.
# ==============================================================================
set -euo pipefail

USERNAME="${1:?Usage: check_student_setup.sh <username> [workdir]}"
WORKDIR="${2:-work}"
ERRORS=0

check() {
    local desc="$1"
    local result="$2"
    if [[ "$result" == "ok" ]]; then
        echo "  ✓ $desc"
    else
        echo "  ✗ $desc → $result"
        ERRORS=$((ERRORS + 1))
    fi
}

echo "Checking setup for: $USERNAME"
echo "Expected workdir: $WORKDIR"

id "$USERNAME" &>/dev/null \
    && check "Account existiert" "ok" \
    || check "Account existiert" "nicht gefunden"

[[ -d "/home/$USERNAME" ]] \
    && check "Home-Verzeichnis /home/$USERNAME" "ok" \
    || check "Home-Verzeichnis /home/$USERNAME" "fehlt"

[[ -d "/home/$USERNAME/$WORKDIR" ]] \
    && check "Arbeitsverzeichnis /home/$USERNAME/$WORKDIR" "ok" \
    || check "Arbeitsverzeichnis /home/$USERNAME/$WORKDIR" "fehlt"

passwd -S "$USERNAME" 2>/dev/null | grep -qv " L " \
    && check "Passwort gesetzt" "ok" \
    || check "Passwort gesetzt" "Account gesperrt oder kein Passwort"

USER_SHELL=$(getent passwd "$USERNAME" | cut -d: -f7)
[[ "$USER_SHELL" == "/bin/bash" ]] \
    && check "Shell ist /bin/bash" "ok" \
    || check "Shell ist /bin/bash" "ist $USER_SHELL"

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "✓ Setup OK für $USERNAME"
    exit 0
else
    echo "✗ $ERRORS Fehler gefunden für $USERNAME"
    exit 1
fi
