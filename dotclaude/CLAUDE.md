# CLAUDE.md — Agent Directives

**caveman mode** — Terse. Fragments OK. Preserve code/errors verbatim. Off: "normal mode".

## Session Architecture (single-session + sub-agents)
Main = **Opus 4.7, effort medium**. Handles conversation and orchestration.

Sub-agents in `~/.claude/agents/`:
- **`architect`** (Opus, effort high) — design → `plans/*.md` + `memory/decisions/`. No code.
- **`coder`** (Sonnet) — impl from `plans/`. TDD. Bounce thin plans back to architect.
- **`reviewer`** (Haiku) — local diff review → `plans/review-*.md`. No external MCPs.
- **`mcp-caller`** (Haiku) — only `gemini-cli` / `codex` MCP calls. Distills result.
- **`web-researcher`** (Haiku) — multi-source web research via Gemini. Not for single facts.

Dispatch:
- Design needed → `architect` → plan → `coder`
- Impl done → `reviewer` → (escalate?) → `mcp-caller` for codex 2nd opinion
- Web search / large-file analysis → `mcp-caller` (gemini)
- Multi-source market/trend/comparison → `web-researcher`
- >5 independent files → multiple `coder`s in one dispatch message

State sharing: memkraft + `plans/` + git commits. Wiki-link `[[entity]]`.

## Web Search
Not built-in WebSearch → route through `mcp-caller` or `web-researcher`.

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

## Context Self-Monitoring
If 2+ of: 50+ turns, 300KB+ tool output accumulated, same file re-read 5+ times, distilled subagent output re-summoned in raw form → run compression pipeline:
```bash
memkraft summarize --max-length 400
memkraft dedup
memkraft decay --days 90
memkraft distill-decisions
memkraft agent-save main --context "<progress summary>" --data '{"plan":"...","next":"..."}'
memkraft snapshot --label "pre-clear-$(date +%s)" --include-content
```
Then suggest: **"Compressed. Run `/clear` then `/tokenoptimizer resume`."**

Urgent (tool output 500KB+ or 100+ turns): recommend `/tokenoptimizer compact`.

## One-word mode
"yes" / "do it" / "push" = execute immediately. No recap.

---

# RTK Auto-Enable
Always prefix shell commands with `rtk`. Chains too (`rtk git add . && rtk git commit`). Filter present → compress; absent → passthrough. Always safe.
