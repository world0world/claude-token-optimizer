# Architecture

## Four token drivers

Every Claude Code turn pays for:

1. **System prompt + tool schemas** — fixed per turn, ~30k tokens. Cache hit = 10% cost.
2. **Context files** — CLAUDE.md, MEMORY.md, per-project memory. Loaded every turn.
3. **Tool output** — file reads, command output. Often the fattest single contribution.
4. **Model output** — priced 5× input; Claude's reply is where it hurts most.

A single technique hits one driver. Combining them multiplies the saving.

## The three-session split

### Why not one Opus session?

Opus output costs $75/1M tokens. 80% of a typical task is mechanical implementation that Sonnet ($15/1M) handles fine. Using Opus for that 80% wastes ~$60 per million output tokens.

### Why three, not two?

Two-session (Opus design + Sonnet implement) captures most savings. The third (Haiku) adds:
- **Independent verification** via Codex (GPT-5) — different family, catches Claude-specific blind spots.
- **Cheap search orchestration** via Gemini MCP — Haiku is 15× cheaper than Opus for simple tool routing.

Haiku's job is *not to think*. It dispatches, parses, files reports. Any thinking gets delegated upward.

### Per-session config

| Session | Model | effortLevel | alwaysThinking | Caveman | MCPs loaded |
|---------|-------|-------------|----------------|---------|-------------|
| 1 Design | Opus 4.7 | high | true | full | none |
| 2 Implement | Sonnet 4.6 | medium | false | full | none |
| 3 Orchestrate | Haiku 4.5 | low | false | ultra | gemini-cli, codex |

MCP scoping matters. MCP schemas are loaded per session, every turn. Keeping Opus/Sonnet sessions MCP-free saves ~3-5k tokens/turn on the expensive models. Haiku absorbs the MCP cost because its per-token rate is 15-75× lower.

MCP scoping in practice: use `enabledMcpjsonServers` allow-lists or different project folders with different `.mcp.json`. (Global `settings.json` applies to all — tradeoff: simplicity vs tighter scope. This repo ships global by default; advanced users can split.)

## Handoff protocol

Sessions don't share memory. They share **files**.

```
Session 1 (Opus)                         Session 2 (Sonnet)                       Session 3 (Haiku)
───────────────                          ─────────────────                        ─────────────────
receive request
write plans/feat-X.md       ────────────> read plans/feat-X.md
                                         implement (TDD loop)
                                         git commit
                                                                   ────────────>  git log --oneline
                                                                                  call mcp__codex__review
                                                                                  write plans/review-feat-X.md
read plans/review-feat-X.md <────────────
amend plans/feat-X.md (v2)  ────────────> re-read, patch
```

No shared context window. No race conditions between windows. Git is the synchronization primitive.

## Memory: MemKraft over MEMORY.md for multi-session

MEMORY.md auto-loads everything each turn. Single index ~1.5KB is fine; grows linearly with project count.

MemKraft template mode injects a ~50-token L1 index into CLAUDE.md. Agent pulls L2 section headers or L3 full files via Read on demand. Net savings grows with memory size.

**Rule of thumb**: keep MEMORY.md for global personal notes; use MemKraft per project for team/session-shared knowledge.

## Caveman output style

Caveman drops articles, filler, and hedging from Claude's output. Technical content preserved. Code blocks untouched. Errors quoted exactly.

On a 2000-token reply, caveman full mode typically drops it to 700-1000. Output tokens dominate cost on expensive models — this stacks with model splitting.

Three intensities:
- `lite` — drop filler, keep grammar. Professional.
- `full` — drop articles, fragments OK.
- `ultra` — abbreviations, arrows for causality.

Session 3 (Haiku) uses `ultra`. Haiku is cheap but its outputs still cost money per token; ultra mode removes everything unnecessary.

## RTK for tool output

Every `Bash` tool call's stdout is appended to Claude's context on the next turn. A verbose `git log` can be 5k tokens; `rtk git log` is ~1k. Applied across every shell operation in a session, this is often the single biggest save.

RTK is a wrapper CLI — install with `cargo install rtk-cli`. The CLAUDE.md rule tells Claude to prefix every shell command. On Linux/WSL an optional PreToolUse hook can auto-wrap; on Windows native the CLAUDE.md rule is the enforcement.

Custom `.rtk/filters.toml` per project handles project-specific tools (build scripts, pipelines).

## Thinking budget

`effortLevel` + `alwaysThinkingEnabled` set the reasoning token budget. Global values force every session to pay the same budget — contradicting the role split.

**Solution**: keep global settings.json free of these flags. Set per-project via `.claude/settings.local.json`, or per-session via slash commands where the CLI supports it. The Opus design session wants `high`; Sonnet impl wants `medium`; Haiku orchestration wants `low`.
