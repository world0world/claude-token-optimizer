# Self-Improvement Protocol

When a mistake, inefficiency, or gap recurs, update the system — not just the current response.

## Trigger conditions
- Same bug class hit 2×
- User correction on same topic 2×
- Tool misuse 2× (wrong args, missing prefix)
- Workflow friction noted after task done

## Update targets (in order)

1. **Project `./CLAUDE.md`** — project-specific rules
2. **Project `memory/decisions/`** — decision log with context
3. **Global `~/.claude/CLAUDE.md`** — cross-project rules (rare, only truly universal)
4. **`~/.claude/refs/`** — detailed refs when CLAUDE.md risks bloat
5. **`.rtk/filters.toml`** — tool output compression for this project
6. **Skill file** — if a workflow pattern emerges

## What to write

- **Rule + rationale** — not just "do X" but "do X because Y seen 3× on 2026-04-10/12/15"
- **Counter-example** — when the rule does NOT apply
- **Check** — how future Claude detects the trigger

## What NOT to update

- One-off mistakes → just fix, don't codify
- User preference that might drift → ask before codifying
- Global CLAUDE.md for project-specific thing → put in project CLAUDE.md instead

## Format

```markdown
## <rule name>
**Trigger:** <when this applies>
**Rule:** <what to do>
**Rationale:** <why, with dates if recurrence-driven>
**Counter:** <when NOT to apply>
```

## Caveat: token cost

Global CLAUDE.md edits load every turn everywhere. Prefer refs/ for details. Keep global file focused on truly global rules.

## Review cadence

Quarterly: read CLAUDE.md + refs top-to-bottom. Delete rules no longer triggering. Merge duplicates. Prune.
