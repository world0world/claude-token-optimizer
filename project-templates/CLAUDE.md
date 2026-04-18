# Project: <NAME>

## Purpose
Brief description of what this project does.

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
