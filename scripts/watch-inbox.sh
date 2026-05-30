#!/usr/bin/env bash
# Emit FEEDBACK_INBOX_CHANGED when inbox.jsonl grows.
set -euo pipefail

INBOX="${1:?usage: watch-inbox.sh <inbox.jsonl>}"
POLL_SECONDS="${POLL_SECONDS:-1}"

if [[ ! -f "$INBOX" ]]; then
  echo "watch-inbox: waiting for $INBOX" >&2
  while [[ ! -f "$INBOX" ]]; do sleep "$POLL_SECONDS"; done
fi

file_size() {
  local n
  n=$(stat -f%z "$1" 2>/dev/null) && { echo "$n"; return; }
  n=$(stat -c%s "$1" 2>/dev/null) && { echo "$n"; return; }
  echo 0
}

emit_if_grown() {
  local cur last=$1
  cur=$(file_size "$INBOX")
  if [[ "$cur" -gt "$last" ]]; then
    echo "FEEDBACK_INBOX_CHANGED $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "$cur"
  else
    echo "$last"
  fi
}

last=$(file_size "$INBOX")

if command -v fswatch >/dev/null 2>&1; then
  while read -r _; do
    last=$(emit_if_grown "$last")
  done < <(fswatch -l 0.5 "$INBOX")
else
  while true; do
    sleep "$POLL_SECONDS"
    last=$(emit_if_grown "$last")
  done
fi
