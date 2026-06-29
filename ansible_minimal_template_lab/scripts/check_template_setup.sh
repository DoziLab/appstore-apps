#!/usr/bin/env bash
set -euo pipefail

username="${1:?usage: check_template_setup.sh <username>}"

if ! id "${username}" >/dev/null 2>&1; then
  echo "User does not exist: ${username}" >&2
  exit 1
fi

if [[ ! -f "/home/${username}/welcome.txt" ]]; then
  echo "Missing welcome file for ${username}" >&2
  exit 1
fi

if [[ ! -d "/srv/dozilab/groups/${username}" ]]; then
  echo "Missing group directory for ${username}" >&2
  exit 1
fi

echo "OK ${username}"
