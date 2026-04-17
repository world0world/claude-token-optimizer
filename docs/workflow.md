# Daily Workflow

## Opening a project

```bash
cd /path/to/project        # MemKraft + per-project CLAUDE.md load automatically
```

Open three Claude Code windows in the same folder:

| Window | Model | Effort | Caveman |
|--------|-------|--------|---------|
| 1 | `/model opus` | high | full |
| 2 | `/model sonnet` | medium | full |
| 3 | `/model haiku` | low | ultra |

Leave them running. Cache stays warm; first-turn write cost is paid once per session.

## Typical feature routine

### Step 1 — Brief in window 1 (Opus)

```
User: "Add feature X that does Y. Constraints: Z."
Opus: <reads memory/, skims code>
      <writes plans/feat-X.md with TDD plan, file list, decision rationale>
      <commits: plans: feat-X draft>
```

### Step 2 — Implement in window 2 (Sonnet)

```
User: "Read plans/feat-X.md. Implement with TDD."
Sonnet: <writes failing test>
        <implements>
        <dispatches parallel Sonnet subagents for independent files>
        <runs rtk pytest>
        <commits: impl: feat-X>
```

Parallel subagents are the secret weapon here. Use the `superpowers:dispatching-parallel-agents` skill.

### Step 3 — Review in window 3 (Haiku)

```
User: "Review latest commit with codex. Save to plans/review-feat-X.md."
Haiku: <rtk git show HEAD>
       <mcp__codex__review tool call with diff>
       <parses codex output, writes plans/review-feat-X.md>
       <memkraft add decision ...>
```

### Step 4 — Amend in window 1 (Opus)

```
User: "Read plans/review-feat-X.md. Update plans/feat-X.md if needed."
Opus: <reviews codex feedback>
      <decides which suggestions to accept>
      <amends plan>
      <commits: plans: feat-X v2>
```

### Step 5 — Patch in window 2 (Sonnet)

Sonnet reads the updated plan, makes changes, tests pass, commits.

### Step 6 — Final verify in window 3

```
User: "Final review. Green-light or regressions?"
```

## Anti-patterns

**Don't** swap models mid-window. Cache cost is ~$0.55 per swap on Opus.

**Don't** copy-paste large tool output between windows. Use file paths + git commits.

**Don't** run the same expensive command in multiple windows. One window runs it, commits the output file, others read.

**Don't** let Opus do mechanical edits. If Opus is editing > 3 files in a row with no design decisions, kick the task to Sonnet.

**Don't** ask Haiku to reason deeply. Haiku routes, summarizes, dispatches. Complex reasoning → bump to Sonnet or Opus.

## Memory discipline

After each session:

```
memkraft add decision "chose-X-over-Y-for-feat-X" \
  --reason "X is faster under write-heavy load (see codex review)"

memkraft add entity "FeatureX" --type feature \
  --notes "owner: session-2, tests: tests/feat_x/"
```

Next session's L1 index picks these up automatically.

## Weekly maintenance

```bash
rtk gain --all --format json > ~/rtk-weekly.json   # adoption metrics
rtk session                                         # check recent adoption %
memkraft doctor                                     # memory health
```

If `rtk session` shows adoption < 80%, refresh the CLAUDE.md rule or update RTK.

## When to break the routine

Small bugs (< 30 min fix): single Sonnet window. No plan file. Just commit.

Exploratory spikes: single Opus window with `/caveman full`. No subagents; Opus thinks, writes throwaway code.

Emergency firefights: single Opus window, no effort cap, no caveman. Token cost doesn't matter when production is down.
