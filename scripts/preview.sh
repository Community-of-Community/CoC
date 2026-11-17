#!/usr/bin/env bash
set -euo pipefail

port="${1:-8000}"
if [[ "$#" -gt 1 ]] || [[ ! "$port" =~ ^[0-9]{1,5}$ ]] || (( 10#$port < 1024 || 10#$port > 65535 )); then
  printf 'Usage: bash scripts/preview.sh [port: 1024–65535]\n' >&2
  exit 2
fi

if ! command -v python3 >/dev/null 2>&1; then
  printf 'Local preview requires Python 3.\n' >&2
  exit 1
fi

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
preview_dir="$(mktemp -d "${TMPDIR:-/tmp}/coc-preview.XXXXXX")"
server_pid=""

cleanup() {
  if [[ -n "$server_pid" ]]; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
  rm -rf -- "$preview_dir"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

cp -R -- "$project_root/site/." "$preview_dir/"
# Ensure logos exist even if site/assets is incomplete.
mkdir -p -- "$preview_dir/assets"
cp -f -- "$project_root/assets/coc-logo.png" "$project_root/assets/coc-logo.jpg" "$preview_dir/assets/" 2>/dev/null || true

printf '\nCoC · local preview\nOpen http://127.0.0.1:%s/\nServing the site folder only. Ctrl+C to stop.\n\n' "$port"
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$preview_dir" &
server_pid="$!"
wait "$server_pid"
