# Project: <NAME>

## Purpose
Brief description of what this project does.

## Paths

- **Working memory**: `./memory/` (entities, decisions, inbox, live-notes)
- **Plans**: `./plans/` (architect output, coder input)
- **Roadmap**: `./memory/live-notes/roadmap.md`
- **Kickoff decision**: `./memory/decisions/` (first file — why this project exists)
- **Global memory**: `C:/Users/every/.claude/projects/C--Users-every/memory/`

Before answering "why did we X?" → read `memory/decisions/` + `memory/live-notes/` first.

## Editing memory

`memory/` is pure markdown. Open this repo folder in **Obsidian** as a vault for graph view + backlinks + live preview. No separate vault needed. Short facts via CLI (`memkraft track`, `memkraft update`); long design docs in Obsidian directly.

## Session Architecture (single-session + sub-agents)

Main = **Opus 4.7, effort medium**. Handles conversation and orchestration.

Sub-agents (`~/.claude/agents/`):

| Agent | Model | Role |
|---|---|---|
| `architect` | Opus (high) | Design → `plans/*.md`, `memory/decisions/`. No code. |
| `coder` | Sonnet | Implements from `plans/`. TDD. Bounces thin plans back. |
| `reviewer` | Haiku | Local diff review → `plans/review-*.md`. No external MCPs. |
| `mcp-caller` | Haiku | Only `gemini-cli` / `codex` MCP calls. Distills result. |

**Dispatch**:
- Design needed → `architect` → plan → `coder`
- Impl done → `reviewer` → (escalate?) → `mcp-caller` for codex 2nd opinion
- Web search / large-file analysis → `mcp-caller` (gemini)
- >5 independent files → dispatch multiple `coder`s in one message

## Handoff convention

- `plans/<feature>.md` — architect writes, coder reads
- `plans/review-<feature>.md` — reviewer writes
- `memory/decisions/<date>-<topic>.md` — architect or main
- `memory/entities/<name>.md` — stable facts, wiki-linked `[[entity]]`
- Code → git commits (coder)
- State sharing: `memkraft agent-save` / `agent-load` / `agent-handoff` / `channel-save`

## memkraft lifecycle

Each sub-agent runs `memkraft agent-inject` on invoke and `memkraft agent-save` + handoff on return. See `~/.claude/agents/*.md` for exact commands.

Manual compression: `/tokenoptimizer compact` → `/clear` → `/tokenoptimizer resume`.

## RTK

All shell commands `rtk`-prefixed (including chains). Custom filters in `.rtk/filters.toml`.

## Local overrides

Per-project settings in `.claude/settings.local.json` (gitignored). Example:
```json
{
  "effortLevel": "high",
  "alwaysThinkingEnabled": true
}
```
