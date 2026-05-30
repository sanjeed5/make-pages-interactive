#!/usr/bin/env bash
# Emit FEEDBACK_INBOX_CHANGED when inbox.jsonl grows.
set -euo pipefail

INBOX="${1:?usage: watch-inbox.sh <inbox.jsonl>}"
POLL_SECONDS="${POLL_SECONDS:-1}"

if [[ ! -f "$INBOX" ]]; then
  echo "watch-inbox: waiting for $INBOX" >&2
  while [[ ! -f "$INBOX" ]]; do sleep "$POLL_SECONDS"; done
fi

emit() {
  echo "FEEDBACK_INBOX_CHANGED $(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

file_size() {
  if stat -f%z "$1" >/dev/null 2>&1; then
    stat -f%z "$1"
  else
    stat -c%s "$1"
  fi
}

if command -v fswatch >/dev/null 2>&1; then
  fswatch -l 0.5 "$INBOX" | while read -r _; do emit; done
else
  last=$(file_size "$INBOX" 2>/dev/null || echo 0)
  while true; do
    sleep "$POLL_SECONDS"
    cur=$(file_size "$INBOX" 2>/dev/null || echo 0)
    if [[ "$cur" -gt "$last" ]]; then
      emit
      last=$cur
    fi
  done
fi
