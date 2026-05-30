---
name: make-pages-interactive
description: Turn a directory of static HTML pages into a live commenting surface. Injects a feedback library, starts a tiny server, and routes user comments into a JSONL inbox that the agent watches and responds to by editing the pages. Trigger phrases — "make this page interactive", "make these pages interactive", "let me comment on this page", "add feedback to these pages", "process my feedback".
---

# Make Pages Interactive

User comments → `feedback/inbox.jsonl` → you edit HTML → append `feedback/history.json` → page reloads with a walkthrough.

```bash
SKILL_ROOT="$(python "$HOME/.agents/skills/make-pages-interactive/scripts/skill_root.py")"
```

## Setup

1. `python "$SKILL_ROOT/scripts/inject.py" <dir>` (`--recursive` if needed)
2. Check port: `curl -s --max-time 2 http://127.0.0.1:5050/info` — reuse server if `artifact_dir` matches; else try 5051+
3. Background: `python "$SKILL_ROOT/lib/server.py" <dir> --port <port>`
4. Give user `http://127.0.0.1:<port>/<file>.html`
5. Watch inbox in this session (below)

## Review loop

```bash
bash "$SKILL_ROOT/scripts/watch-inbox.sh" "<dir>/feedback/inbox.jsonl"
```

Use `notify_on_output` on `FEEDBACK_INBOX_CHANGED`. On wake: process → re-arm. Fallback: **"process my feedback"**.

## Process feedback

1. Read `inbox.jsonl` (one batch per line)
2. Skip comment ids already in `history.json` → `changes[*].in_response_to`
3. Edit HTML; wrap changes in `<span data-cf-change="ch-<slug>">`
4. Append to `history.json` (newest last):
   ```json
   { "batch_id": "b-...", "timestamp": "...", "comments": [...], "changes": [{ "id": "ch-...", "in_response_to": ["<comment id>"], "anchor": "ch-...", "title": "...", "description": "..." }] }
   ```
5. Re-arm watcher

## Other

- **Pending backlog:** diff inbox vs history, process, arm watcher
- **Stop server:** `lsof -ti:<port> | xargs kill`
- **Remove tags:** `python "$SKILL_ROOT/scripts/inject.py" <dir> --remove`

## Gotchas

- Serve via `server.py` (not `file://`)
- Do not leave after starting the server if the user is reviewing
