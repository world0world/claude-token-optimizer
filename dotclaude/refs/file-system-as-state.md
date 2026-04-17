# File System as State

Sessions don't share memory. Files do. Git commits do. Use the filesystem as the coordination primitive.

## Principles

1. **Single source of truth** — one file owns each piece of state. No duplication.
2. **Explicit handoffs** — session A writes file, session B reads file. No implicit assumption.
3. **Git is the boundary** — committed state is canonical; uncommitted is scratch.
4. **Filename = contract** — `plans/feat-X.md` owned by S1, `memory/live-notes/` owned by S2, `plans/review-*.md` owned by S3.

## Conventions

### plans/
- `plans/<feature>.md` — design doc (S1 writes, S2 reads)
- `plans/<feature>-v2.md` — revision after review (S1 writes)
- `plans/review-<feature>.md` — codex review output (S3 writes, S1 reads)

### memory/ (MemKraft)
- `memory/entities/<name>.md` — stable per-entity facts (any session)
- `memory/decisions/<date>-<topic>.md` — why X over Y (S1 or S3)
- `memory/live-notes/<date>-<topic>.md` — WIP thoughts (S2 during impl)
- `memory/sessions/<session-id>.md` — session checkpoint
- `memory/inbox/` — untriaged, gitignored

### .rtk/
- `.rtk/filters.toml` — project filter config
- `.rtk/tee/` — saved failed command outputs, gitignored

### .claude/
- `.claude/settings.local.json` — per-session model/effort, gitignored

## Handoff patterns

**Design → impl:**
S1 commits `plans/feat-X.md`. S2 `rtk git pull` or reads directly. Never paste plan content across windows.

**Impl → review:**
S2 commits code. S3 `rtk git log --oneline -5` finds commit, reads diff, calls codex MCP, writes `plans/review-feat-X.md`.

**Review → amend:**
S1 reads review, updates plan, commits. S2 patches impl.

## Anti-patterns

- **Copy-paste between sessions** — defeats cache, duplicates context.
- **Write to `memory/` from outside project** — breaks per-project scoping.
- **Edit `plans/feat-X.md` from S2** — ownership violation; S2 proposes, S1 amends.
- **Uncommitted state as truth** — if not committed, next session doesn't see it.

## Race condition avoidance

Two windows editing same file = last-write-wins overwrite. Rules:
- One window = author per file (see ownership above)
- Use git: author commits, consumer pulls
- If concurrent edit unavoidable, use separate filenames (`plans/feat-X-s1.md`, `plans/feat-X-s3-notes.md`)
