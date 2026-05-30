# make-pages-interactive

Turn any folder of static HTML pages into a live commenting surface. Works with **Cursor**, **Claude Code**, **Codex**, and other terminal agents.

Originally built for iterating on research artifacts (long HTML reports with plots, tables, explanations) but works for any folder of HTML: docs, design mocks, generated reports, prototype UIs.

![Screenshot of make-pages-interactive in action](screenshot.png)

---

## How it works

```
                  ┌──────────────────┐
   user highlights│   feedback.js    │   POST /feedback
   / clicks  ───▶ │  (in every page) │ ───────────────┐
                  └──────────────────┘                 ▼
                                              ┌────────────────┐
                  ┌──────────────────┐  poll  │   server.py    │
   page reloads ◀─│   feedback.js    │ ◀───── │  (stdlib HTTP) │
   with walkthru  └──────────────────┘history │                │
                                              └───────┬────────┘
                                                      │ append
                                          ┌───────────▼────────────┐
                                          │  feedback/inbox.jsonl  │
                                          └───────────┬────────────┘
                                                      │ watch (same session)
                                                      ▼
                                          ┌────────────────────────┐
                                          │  Coding agent          │
                                          │  edits HTML, appends   │
                                          │  feedback/history.json │
                                          └────────────────────────┘
```

The skill is **just three pieces**:

| File | Role |
|------|------|
| `lib/feedback.js` | Client library injected into every page. Handles text selection, element selection, comment editor, page-reload walkthrough. |
| `lib/feedback.css` | Styles for the comment UI. |
| `lib/server.py` | ~250-line stdlib-only HTTP server. Serves the page directory, accepts comment POSTs, serves the lib/ files from `/lib/*`. Binds to loopback by default. Auto-shuts-down on parent death or 10 min of idle. |

Plus glue:

| File | Role |
|------|------|
| `SKILL.md` | Agent-facing spec (setup, watch inbox, process feedback). |
| `scripts/inject.py` | Idempotently injects (or removes) the two `<link>`/`<script>` tags in every `*.html` in a directory. |
| `scripts/watch-inbox.sh` | Portable inbox watcher (`fswatch` or poll) for agents without a native file monitor. |
| `scripts/skill_root.py` | Prints the skill install path for agent-agnostic commands. |
| `scripts/update.py` | `git pull --ff-only` inside the skill directory. |

---

## Install

```bash
git clone https://github.com/sanjeed5/make-pages-interactive \
  ~/.agents/skills/make-pages-interactive
```

Agents that discover skills from `~/.agents/skills/` (Cursor, Codex, etc.) pick it up automatically. For Claude Code, symlink if needed:

```bash
ln -s ~/.agents/skills/make-pages-interactive ~/.claude/skills/make-pages-interactive
```

Updates:

```bash
python ~/.agents/skills/make-pages-interactive/scripts/update.py
```

Or ask your agent to "update the make-pages-interactive skill".

---

## Usage

In any agent session, say:

> "Make these pages interactive."

The agent will:

1. Inject the feedback library tags into every `*.html` in the target directory.
2. Create `feedback/inbox.jsonl` and `feedback/history.json`.
3. Pick a free port (5050 by default).
4. Start the server in the background.
5. Tell you the URL to open (`http://127.0.0.1:5050/...`).
6. Watch `feedback/inbox.jsonl` in the same session and iterate on feedback.

Open the URL. Comment away. The agent edits the page; it auto-reloads after `history.json` updates.

### Watching the inbox

- **Claude Code:** `Monitor on path: feedback/inbox.jsonl`
- **Others:** `bash "$SKILL_ROOT/scripts/watch-inbox.sh" feedback/inbox.jsonl` with `notify_on_output` on `^FEEDBACK_INBOX_CHANGED`
- **Fallback:** "process my feedback"

See `SKILL.md`.

### Removing the feedback layer

```bash
SKILL_ROOT="$(python ~/.agents/skills/make-pages-interactive/scripts/skill_root.py)"
python "$SKILL_ROOT/scripts/inject.py" ./your-dir --remove
```

Or ask the agent to remove the feedback layer.

---

## How the server shuts down

1. **Parent-process death** *(automatic, ~5–10 s)* — when the shell that launched the server exits.
2. **Idle timeout** *(default 10 min)* — no browser tabs polling keeps the server alive.
3. **Manual stop** — `lsof -ti:5050 | xargs kill` or ask the agent to stop the server.

---

## Comment types

- **Text selection** — highlight any text, click "comment".
- **Element selection** — click "select element", then click a block (image, table, section).
- **Page-level** — "+ general" for notes not tied to a region.

Comments batch client-side into one POST so the agent responds to a coherent set.

---

## When the agent responds

1. A "processing…" banner appears.
2. Tab title shows `⏳` while waiting, `🔔` when changes are ready.
3. The agent edits HTML and appends to `feedback/history.json`.
4. The page polls, auto-reloads (scroll preserved), and offers a walkthrough of changes.

---

## Repo layout

```
make-pages-interactive/
├── SKILL.md
├── README.md
├── lib/
│   ├── feedback.js
│   ├── feedback.css
│   └── server.py
└── scripts/
    ├── inject.py
    ├── update.py
    ├── skill_root.py
    └── watch-inbox.sh
```

---

## License

MIT. See [LICENSE](LICENSE).

Fork of [paraschopra/make-pages-interactive](https://github.com/paraschopra/make-pages-interactive).
