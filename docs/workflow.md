# Daily Workflow

## Opening a project

```bash
cd /path/to/project   # memkraft + per-project CLAUDE.md load automatically
```

Open **one** Claude Code window. Main session = Opus 4.7 / effort medium. Sub-agents dispatch from here.

## Typical feature routine

### Step 1 — Brief main (Opus)

```
User: "Add feature X that does Y. Constraints: Z."
Main: <reads memory/, skims code>
      <decides: needs design → dispatch architect>
```

### Step 2 — Architect (Opus/high)

Main invokes `architect` sub-agent via Agent tool. Architect:
- Runs `memkraft agent-inject architect` on invoke
- Writes `plans/feat-X.md` (file list, TDD plan, decision rationale)
- Writes `memory/decisions/<date>-feat-X.md`
- Returns: `memkraft agent-save` + `distill-decisions` + `agent-handoff coder`

### Step 3 — Coder (Sonnet)

Main dispatches `coder` with task ID. Coder:
- `memkraft agent-inject coder` + `agent-load architect` to pick up plan
- Writes failing test → implements → `rtk pytest`
- Commits `[coder] impl: feat-X`
- Returns: `agent-save` with SHA + `agent-handoff coder reviewer`
- Plan thin? STOP, bounce to architect.

**Parallel**: >5 independent files → main dispatches multiple `coder`s in a single Agent-tool message.

### Step 4 — Reviewer (Haiku)

Main dispatches `reviewer`. Reviewer:
- `agent-inject reviewer` + `agent-load coder` to get SHA/files
- Runs `rtk git show HEAD`
- Writes `plans/review-feat-X.md`: matches plan? tests? findings?
- Returns: `ship` / `revise` / `escalate-to-mcp-caller`
- `open-loops` extracts unresolved items.

### Step 5 — (Optional) MCP-caller (Haiku)

If reviewer escalates or main wants codex 2nd opinion / web search:
- `mcp-caller` calls `mcp__codex__codex` or `mcp__gemini-cli__ask-gemini`
- Caches result: `memkraft channel-save "mcp-<hash>"`
- Returns distilled findings (Source / Key findings / Confidence).

### Step 6 — Main decides next

Main reads review + any MCP input, decides:
- Ship → commit, update memory
- Revise → dispatch `coder` again with notes
- Redesign → bounce to `architect`

## Context management

Hooks (`~/.claude/settings.json`):
- **PreCompact** → `memkraft snapshot --include-content` + `agent-save main`
- **Stop** → `agent-save main` + `distill-decisions` + `open-loops` (async)
- **SubagentStop** → `memkraft dedup` (async)

Self-monitoring (main watches for):
- 50+ turns
- 300KB+ tool output accumulated
- Same file re-read 5+ times
- Distilled subagent result re-summoned in raw form

→ Run `/tokenoptimizer compact` → `/clear` → `/tokenoptimizer resume`.

## Memory discipline

Architect / main writes decisions via `memkraft` entities. Wiki-links `[[FeatureX]]` auto-resolve.

```bash
memkraft remember "chose X over Y for feat-X — faster under write-heavy load"
memkraft link FeatureX --type feature
```

## Weekly maintenance

```bash
/tokenoptimizer dream    # memkraft dream + decay + dedup + doctor + stats
rtk session              # RTK adoption %
```

If adoption < 80%, refresh CLAUDE.md rule or update RTK.

## Anti-patterns

- **Don't** do mechanical edits in main — dispatch `coder`.
- **Don't** call `codex` / `gemini` MCPs directly from main — route through `mcp-caller`.
- **Don't** let `reviewer` rewrite code — bounce to `coder`.
- **Don't** copy-paste large tool output back into main — use file paths + `memkraft channel-load`.
- **Don't** swap main model mid-session. Cache cost is real.

## When to skip orchestration

- Small bugs (<30 min): main handles inline. No plan file.
- Exploratory spikes: main in caveman mode, throwaway code.
- Emergency firefights: no effort cap, skip review chain.
