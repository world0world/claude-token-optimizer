# CLAUDE.md — Agent Directives

**caveman mode** — Terse. Fragments OK. Preserve code/errors verbatim. Off: "normal mode".

## Session Architecture (3 sessions per project, fixed)
- **S1 Opus 4.7** — Design/review. Writes `plans/` + `memory/decisions/`.
- **S2 Sonnet 4.6** — Implementation. Logs to `memory/live-notes/`.
- **S3 Haiku 4.5** — Orchestration + code review via `codex` MCP.

No mid-session `/model` switching. Shared state: memkraft + `plans/` + git commits. Use wiki-links `[[entity]]`.
Handoff: S1 decisions → S2 implements → S3 codex review → decisions updated.

## Web Search
Prefer **`gemini-cli` MCP** (`ask-gemini` + `googleSearch`) over built-in WebSearch.

## Pre-Work
- **Delete before build.** Files >300 LOC: strip dead code first, separate commit.
- **Phased execution.** Multi-file refactor = phases ≤5 files. Verify → wait → next.
- **Plan ≠ Build.** "plan first" = plan output only. Vague asks = outline for approval.
- **Spec-driven for 3+ step features.** Interview via `AskUserQuestion`.

## Edit Safety
- **Re-read before each edit, read again after.** Edit silently fails on stale context. ≤3 edits per file before verify.
- **No semantic search.** Rename = grep direct calls + types + string literals + dynamic imports + re-exports + tests. Assume grep missed something.
- **One source of truth.** Never duplicate state to fix display bugs.
- **Destructive safety.** Verify no references before delete. No force-push without instruction.

## Code Quality
- **Forced verification.** Before "done": type-check strict + lint + tests + log check. No tests? State it.
- **Senior fix, not band-aid.** Propose/implement structural solutions.
- **Don't over-engineer.** Strip speculative code. No robotic comment blocks.

## Context Management
- **Sub-agent swarming for >5 independent files.** ~167K tokens per agent.
- **Context decay.** After 10+ messages → re-read before editing. Don't trust memory.
- **File reads capped at 2000 lines.** Use offset/limit for >500 LOC.
- **Tool result truncation at 50KB.** Suspect incomplete → re-run narrower.

## One-word mode
"yes" / "do it" / "push" = execute immediately. No recap.

---

# RTK Auto-Enable
Always prefix shell commands with `rtk`. Chains too (`rtk git add . && rtk git commit`). Filter present → compress; absent → passthrough. Always safe.

Refs: `~/.claude/refs/` — rtk-commands, superpowers, cache-awareness, self-improvement, file-system-as-state.
