# Architecture

## Four token drivers

Every Claude Code turn pays for:

1. **System prompt + tool schemas** — fixed per turn, ~30k tokens. Cache hit = 10% cost.
2. **Context files** — CLAUDE.md, MEMORY.md, per-project memory. Loaded every turn.
3. **Tool output** — file reads, command output. Often the fattest single contribution.
4. **Model output** — priced 5× input; Claude's reply is where it hurts most.

A single technique hits one driver. Combining them multiplies the saving.

## Single session + sub-agents

Main = **Opus 4.7, effort medium**. Orchestrates. Sub-agents run in isolated context windows and return distilled summaries only.

| Sub-agent | Model | Role | Why this tier |
|---|---|---|---|
| `architect` | Opus (high) | Design → `plans/*.md`, `memory/decisions/` | Trade-off analysis needs strongest reasoning, run infrequently |
| `coder` | Sonnet | Impl from plans, TDD | 80% of work is mechanical — Sonnet is 5× cheaper than Opus |
| `reviewer` | Haiku | Local diff review → `plans/review-*.md` | Pattern-matching, no deep reasoning → cheapest tier |
| `mcp-caller` | Haiku | gemini/codex MCP calls | Dispatch + distill, no thinking |
| `web-researcher` | Haiku | Multi-source web research | Same — routing + summarization only |

### Why isolated sub-agents vs multi-session

Earlier design: 3 manual Claude Code windows (Opus/Sonnet/Haiku). Works, but:
- User tracks which window does what
- `/model` swap invalidates cache
- No auto-handoff — manual copy-paste between windows

Single-session + sub-agent fixes all three:
- Main dispatches via Agent tool
- Each sub-agent has its **own context window** — raw tool output never leaks back to main
- Cache per sub-agent persists across invocations within a session
- `memkraft agent-save/load/handoff` shares state across dispatches

### MCP scoping

MCP schemas are loaded every turn for sessions that have them registered. Sub-agents `architect`/`coder`/`reviewer` have **no MCP tools** in their frontmatter → zero schema overhead. Only `mcp-caller` and `web-researcher` pay the gemini/codex schema tax, and they're Haiku.

Global `settings.json` no longer stores `mcpServers` (user-scope doesn't load them). MCPs are registered via `claude mcp add -s user` — each sub-agent's `tools:` allowlist decides which MCPs it actually sees.

## Handoff protocol

Sub-agents don't share a live context. They share **files** + **memkraft state**.

```
main (Opus)                architect                   coder                      reviewer
───────                    ─────────                   ─────                      ────────
receive request
dispatch architect   ───>  agent-inject architect
                           write plans/feat-X.md
                           agent-save + handoff coder
                    <───   return summary
dispatch coder       ───>                              agent-inject coder
                                                       agent-load architect
                                                       impl (TDD) + commit
                                                       agent-save + handoff reviewer
                    <───                               return SHA + summary
dispatch reviewer    ───>                                                         agent-inject reviewer
                                                                                  agent-load coder
                                                                                  write plans/review-feat-X.md
                    <───                                                          return verdict
decide: ship/revise/escalate
```

Synchronization primitives: git commits + `plans/*.md` + `memkraft channel-save`.

## Memory: MemKraft over MEMORY.md

MEMORY.md auto-loads everything each turn. MemKraft template mode injects ~50-token L1 index into CLAUDE.md. Agent pulls L2 headers or L3 full files via Read on demand.

Plus the sub-agent lifecycle commands:
- `agent-inject <agent>` — prime an agent's context with prior task state
- `agent-save <agent>` — persist context snapshot on return
- `agent-handoff <from> <to>` — hand off task ID with note
- `channel-save/load` — cache MCP results for reuse
- `snapshot --include-content` — rollback point (PreCompact hook uses this)
- `distill-decisions` / `open-loops` — extract structured state

## Context compaction (automatic + manual)

Hooks in `settings.json`:
- **PreCompact** → `memkraft snapshot` + `agent-save main` before Claude's auto-compact
- **Stop** → `agent-save main` + `distill-decisions` + `open-loops` (async)
- **SubagentStop** → `memkraft dedup` (async)

Main self-monitors: if 50+ turns, or 300KB+ tool output accumulated, or same file re-read 5+ times, or distilled result re-summoned raw → run compression pipeline. Then `/clear` + `/tokenoptimizer resume` restores state clean.

## Caveman output style

Drops articles, filler, hedging. Technical content preserved. Code/errors quoted exactly. On a 2000-token reply, caveman full drops it to 700-1000. Output tokens dominate cost on expensive models — this stacks with model splitting.

Haiku sub-agents use `ultra`; main uses `full`.

## RTK for tool output

Every `Bash` call's stdout is appended to Claude's next-turn context. Verbose `git log` = ~5k tokens; `rtk git log` = ~1k. Applied across every shell operation, often the single biggest save.

Install: `cargo install rtk-cli`. CLAUDE.md rule tells agents to prefix every shell command. Linux/WSL: optional PreToolUse hook auto-wraps. Windows native: CLAUDE.md rule only.

Project-specific filters in `.rtk/filters.toml`.

## Thinking budget

`effortLevel` + `alwaysThinkingEnabled` set reasoning budget. Global value forces all sub-agents to pay same budget — contradicting the tier split.

**Solution**: main is set `model: opus, effortLevel: medium` globally. Each sub-agent md file declares its own `model:` — Claude Code harness uses per-agent budget. Don't set global `alwaysThinkingEnabled: true` unless you want Haiku to think too (expensive).
