---
description: Token optimizer — setup/verify/workflow/compact/snapshot/resume/handoff/dream. Main session's memkraft + context ops.
argument-hint: "[help|verify|workflow|compact|snapshot|resume|handoff|dream]"
allowed-tools: Bash, Read, Write, Edit
---

# Token Optimizer

User arg: `$ARGUMENTS`

Dispatch based on first word of `$ARGUMENTS`:

---

## `` (empty) → SETUP current project (memkraft-as-vault mode)

Scaffolds the current directory into a memkraft-first project — `memory/` IS the vault, optionally opened in Obsidian for graph view. No separate Obsidian vault path needed.

Run:
```bash
bash ~/claude-token-optimizer/scripts/setup-project.sh
```

Creates:
- `memory/{entities,decisions,inbox,live-notes}/` — markdown memory
- `memory/live-notes/roadmap.md` — fill in milestones
- `memory/decisions/<today>-kickoff.md` — fill in one-line why
- `plans/` — architect output dir
- `.rtk/filters.toml` — project token filters
- `CLAUDE.md` — with paths block + Obsidian hint
- `.obsidian/app.json` — lets user open folder in Obsidian instantly
- `.gitignore` — memory/inbox, .memkraft, .rtk/tee, .obsidian/workspace

Also runs `memkraft index` so search picks up new files.

After scaffold, instruct user:
1. Fill in `memory/decisions/<today>-kickoff.md` (the "why")
2. Fill in `memory/live-notes/roadmap.md` (milestones)
3. (Optional) Open folder in Obsidian for editing with graph view
4. `rtk git add ... && rtk git commit`

---

## `verify` → VERIFY install

Run:
```bash
memkraft --version && codex --version && gemini --version 2>&1 | head -1 && rtk --version && claude mcp list
memkraft doctor --fix
memkraft mcp doctor 2>/dev/null || true
```
Flag missing/failing with fix hint from `~/claude-token-optimizer/docs/troubleshooting.md`.
memkraft 2.0+ required. Older: `memkraft selfupdate`.

Also verify sub-agents exist:
```bash
ls ~/.claude/agents/{architect,coder,reviewer,mcp-caller,web-researcher}.md
```

---

## `workflow` → SHOW single-session + sub-agent workflow

Main = Opus 4.7, effort medium. Sub-agents in `~/.claude/agents/`:

| Agent | Model | Role | memkraft lifecycle |
|---|---|---|---|
| `architect` | Opus/high | design → `plans/`, `memory/decisions/` | invoke: `agent-inject architect` / return: `agent-save` + `distill-decisions` + `agent-handoff coder` |
| `coder` | Sonnet | impl from plans, TDD | invoke: `agent-load architect` / return: `agent-save` + `agent-handoff reviewer` |
| `reviewer` | Haiku | local diff review → `plans/review-*.md` | invoke: `agent-load coder` / return: `agent-save` + `open-loops` |
| `mcp-caller` | Haiku | gemini/codex MCP calls | invoke: `channel-load <cache>` / return: `channel-save` + `agent-save` |
| `web-researcher` | Haiku | multi-source web research via Gemini | invoke: `agent-inject` / return: `agent-save` |

**Dispatch flow**: main (Opus) → architect → main → coder → main → reviewer → (escalate?) → mcp-caller → main.

**Handoff chain**:
```bash
memkraft agent-handoff architect coder --task T-42
memkraft agent-handoff coder reviewer --task T-42
memkraft agent-handoff reviewer mcp-caller --task T-42  # only if escalate
```

**Parallel**: >5 independent files → dispatch multiple `coder`s in ONE message.

---

## `compact` → MANUAL compression pipeline

Run in order, report what happened at each step:
```bash
memkraft summarize --max-length 400
memkraft dedup
memkraft decay --days 90
memkraft distill-decisions
memkraft open-loops
memkraft agent-save main --context "manual compact $(date -Iseconds)" --data '{"reason":"user-triggered"}'
memkraft snapshot --label "pre-clear-$(date +%s)" --include-content
```
After completion: tell user **"State saved. Run `/clear` then `/tokenoptimizer resume` in new session."**

---

## `snapshot [label]` → SAVE rollback point

If `$ARGUMENTS` = "snapshot foo":
```bash
memkraft snapshot --label "foo-$(date +%s)" --include-content
memkraft snapshot-list | head -5
```
Returns snapshot ID for time-travel reference.

---

## `resume [agent]` → LOAD state after /clear

If no agent specified → default "main":
```bash
memkraft agent-inject ${AGENT:-main} --max-history 10
```
Paste result block into context. Report what was restored (task, decisions, open loops).

If user specifies agent (e.g. `resume coder`):
```bash
memkraft agent-inject coder --task "$TASK_ID" --max-history 10
```

---

## `handoff <from> <to> [note]` → AGENT handoff

Parse `$ARGUMENTS` = "handoff architect coder plan locked":
```bash
memkraft agent-handoff <from> <to> --task "$TASK_ID" --note "<note>"
```
Confirm handoff saved.

---

## `dream` → MAINTENANCE cycle (nightly recommended)

```bash
memkraft dream --resolve-conflicts
memkraft decay --days 90
memkraft dedup
memkraft doctor --fix
memkraft health 2>/dev/null || true
memkraft stats --export json
```
Report: conflicts resolved, stale entries flagged, duplicates merged, health status.

---

## `help` → SHOW usage

```
/tokenoptimizer                  scaffold current project
/tokenoptimizer verify           check tools + MCPs + agents
/tokenoptimizer workflow         show sub-agent dispatch flow
/tokenoptimizer compact          manual context compression pipeline
/tokenoptimizer snapshot [label] save rollback point
/tokenoptimizer resume [agent]   restore state after /clear (default: main)
/tokenoptimizer handoff <from> <to> [note]  agent-to-agent handoff
/tokenoptimizer dream            nightly maintenance (dedup/decay/conflicts)
/tokenoptimizer help             this message
```

Repo: `~/claude-token-optimizer/` · Agents: `~/.claude/agents/` · Hooks: `~/.claude/settings.json`

---

If `$ARGUMENTS` first word is not in the above list, show `help` and ask user to pick valid subcommand.
