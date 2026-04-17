# Project: <NAME>

## Purpose
Brief description of what this project does.

## Three-Session Workflow

This project uses the multi-session pattern from `claude-token-optimizer`:

| Session | Model | Role |
|---------|-------|------|
| 1 | Opus 4.7 (high effort) | Design, plan writing, review diffs |
| 2 | Sonnet 4.6 (medium) | Implement `plans/*.md`, parallel subagents |
| 3 | Haiku 4.5 (low) | Codex MCP review, Gemini MCP search, orchestration |

All three share `memory/` (MemKraft), `plans/`, and git history.

## Handoff convention

- **Design** → `plans/<feature>.md` (session 1 writes)
- **Decision log** → `memory/decisions/` (session 1 or 3)
- **Entity facts** → `memory/entities/`
- **Session notes** → `memory/sessions/`
- **Code** → committed directly (session 2)
- **Reviews** → `plans/review-<feature>.md` (session 3)

## RTK

All shell commands are `rtk`-prefixed. Custom filters in `.rtk/filters.toml`.

## MemKraft

Store:
- `memory/entities/<name>.md` — stable facts per entity
- `memory/decisions/<date>-<topic>.md` — why we chose X over Y
- `memory/live-notes/` — WIP thoughts

Search: `memkraft search <term>`

## Local overrides

Put per-project Claude Code settings in `.claude/settings.local.json` (gitignored). Example:
```json
{
  "effortLevel": "high",
  "alwaysThinkingEnabled": true
}
```
Adjust per-session by opening this folder with a different `/model`.
