---
description: Initialize current project with Claude Token Optimizer scaffold (MemKraft memory, RTK filters, plans/, per-session effort config)
allowed-tools: Bash, Write, Read, Edit
---

# /tokenoptimizer

Set up the current working directory with the Claude Token Optimizer scaffold. Run this on any new project to enable the 3-session cost-optimized workflow.

## What this does

1. **MemKraft memory init** — `memory/` with entities/, decisions/, sessions/ subdirs for multi-session shared state
2. **RTK project filters** — `.rtk/filters.toml` for project-specific tool output compression
3. **Plans directory** — `plans/` for Opus→Sonnet handoff documents
4. **Per-project effort config** — `.claude/settings.local.json` with reasonable defaults (not committed)
5. **Project CLAUDE.md** — if absent, writes template describing the 3-session convention
6. **.gitignore guards** — ensures `memory/inbox/`, `.memkraft/`, `.rtk/tee/`, `.claude/settings.local.json` are ignored

## Arguments

`$ARGUMENTS` — optional project name (used only in the CLAUDE.md template header). If empty, uses directory name.

## Steps

Execute in order. Report each step's result concisely.

### 1. Pre-flight check

```bash
pwd
command -v memkraft >/dev/null || echo "WARN: memkraft not installed; install via: pipx install memkraft"
command -v rtk >/dev/null || echo "WARN: rtk not installed; install via: cargo install rtk-cli"
```

If `memkraft` missing, abort and tell user to run the claude-token-optimizer install script first.

### 2. MemKraft init

```bash
PYTHONUTF8=1 PYTHONIOENCODING=utf-8 memkraft init --template claude-code
```

Preserves existing files. Safe to re-run.

### 3. RTK filters

Create `.rtk/filters.toml` if absent. Use the Python ML template if the project has a `pyproject.toml` or `requirements.txt`, otherwise use the generic template. Template content lives in `~/claude-token-optimizer/rtk/filters-samples/` — copy whichever applies. If that path does not exist on this machine, inline a minimal template:

```toml
schema_version = 1

# [filters.my-tool]
# match_command = "^my-tool"
# strip_ansi = true
# strip_lines_matching = ["^\\s*$"]
# max_lines = 40
```

### 4. Plans directory

```bash
mkdir -p plans
[ -f plans/.gitkeep ] || touch plans/.gitkeep
```

### 5. Per-project settings.local.json

Create `.claude/settings.local.json` only if absent. Content:

```json
{
  "_comment": "Per-project overrides. NOT committed. Adjust effortLevel when opening a specific session.",
  "effortLevel": "medium",
  "alwaysThinkingEnabled": false
}
```

Tell the user: for the design (Opus) session, bump `effortLevel` to `high` and `alwaysThinkingEnabled` to `true` in this file before opening that window. For Sonnet implementation: `medium` / `false`. For Haiku orchestration: `low` / `false`.

### 6. Project CLAUDE.md

If `./CLAUDE.md` does not exist, write one with this structure (replace `<NAME>` with `$ARGUMENTS` or the current dir name):

```markdown
# Project: <NAME>

## Three-Session Workflow

| Session | Model | Role |
|---------|-------|------|
| 1 | Opus (high) | Design, plans, review |
| 2 | Sonnet (medium) | Implementation |
| 3 | Haiku (low) | Codex review, search, orchestration |

All three share `memory/`, `plans/`, and git.

## Handoff

- Design → `plans/<feature>.md`
- Decisions → `memory/decisions/`
- Entities → `memory/entities/`
- Code → git commits (session 2 authors)
- Reviews → `plans/review-<feature>.md`

## RTK

All shell commands `rtk`-prefixed. Custom filters in `.rtk/filters.toml`.
```

### 7. .gitignore guards

Append (if not already present):
```
memory/inbox/
.memkraft/
.rtk/tee/
.claude/settings.local.json
```

### 8. Report

Summarize what was created, what was preserved, and next steps:

- If new project: remind user to `rtk git add CLAUDE.md memory/ .rtk/ plans/ .gitignore` and commit
- Print the 3-window opening sequence:
  ```
  Window 1: /model opus     → edit settings.local.json: high/true
  Window 2: /model sonnet   → edit settings.local.json: medium/false
  Window 3: /model haiku    → edit settings.local.json: low/false
  ```
- Suggest `memkraft doctor` to confirm memory health

Keep output under ~15 lines. Caveman style if active.
