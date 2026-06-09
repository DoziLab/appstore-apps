#!/usr/bin/env bash
# ==============================================================================
# DoziLab: Passwort eines Student-Accounts zurücksetzen.
# Kann vom Lehrer manuell aufgerufen werden.
#
# Usage: reset_password.sh <username> <new_password>
# ==============================================================================
set -euo pipefail

USERNAME="${1:?Usage: reset_password.sh <username> <new_password>}"
NEW_PASSWORD="${2:?Usage: reset_password.sh <username> <new_password>}"

# Prüfen ob Account existiert
if ! id "$USERNAME" &>/dev/null; then
    echo "ERROR: Account '$USERNAME' nicht gefunden" >&2
    exit 1
fi

# Passwort setzen
echo "${USERNAME}:${NEW_PASSWORD}" | chpasswd
echo "✓ Passwort für '$USERNAME' zurückgesetzt"

# Passwort-Änderung beim nächsten Login erzwingen
chage -d 0 "$USERNAME"
echo "✓ Passwort-Änderung beim nächsten Login erzwungen"
