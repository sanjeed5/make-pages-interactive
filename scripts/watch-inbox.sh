#!/usr/bin/env bash
set -euo pipefail

INBOX="${1:?usage: watch-inbox.sh <inbox.jsonl>}"
POLL_SECONDS="${POLL_SECONDS:-1}"

if [[ ! -f "$INBOX" ]]; then
  echo "watch-inbox: waiting for $INBOX" >&2
  while [[ ! -f "$INBOX" ]]; do sleep "$POLL_SECONDS"; done
fi

file_size() {
  stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null || echo 0
}

emit_if_grown() {
  local cur
  cur=$(file_size "$INBOX")
  (( cur > last )) || return 0
  last=$cur
  echo "FEEDBACK_INBOX_CHANGED $(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

last=$(file_size "$INBOX")

if command -v fswatch >/dev/null 2>&1; then
  while read -r _; do emit_if_grown; done < <(fswatch -l 0.5 "$INBOX")
else
  while true; do
    sleep "$POLL_SECONDS"
    emit_if_grown
  done
fi
