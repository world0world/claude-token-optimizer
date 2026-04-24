#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="${1:-$PWD}"

echo "==> project setup: $PROJECT_DIR"
cd "$PROJECT_DIR"

# MemKraft init
if command -v memkraft >/dev/null 2>&1; then
  PYTHONUTF8=1 PYTHONIOENCODING=utf-8 memkraft init --template claude-code || true
else
  echo "memkraft missing — run scripts/install.sh first"
  exit 1
fi

# .rtk filters
mkdir -p .rtk
if [ ! -f .rtk/filters.toml ]; then
  cp "$REPO_DIR/rtk/filters-samples/generic.toml" .rtk/filters.toml
  echo "==> .rtk/filters.toml created. customize for project tools."
fi

# plans/ dir for Opus→Sonnet handoff
mkdir -p plans
[ -f plans/.gitkeep ] || touch plans/.gitkeep

# per-project CLAUDE.md template if absent
if [ ! -f CLAUDE.md ]; then
  cp "$REPO_DIR/project-templates/CLAUDE.md" CLAUDE.md
  echo "==> CLAUDE.md created. edit to describe this project."
fi

# roadmap skeleton
mkdir -p memory/live-notes
if [ ! -f memory/live-notes/roadmap.md ]; then
  PROJECT_NAME="$(basename "$PROJECT_DIR")"
  TODAY="$(date +%Y-%m-%d)"
  cat > memory/live-notes/roadmap.md <<EOF
# Roadmap — $PROJECT_NAME

Started: $TODAY

## Goal
<one-line success criterion>

## Milestones
- [ ] M1 — <deliverable>
- [ ] M2 — <deliverable>
- [ ] M3 — <deliverable>

## Open questions
- ?

## Related
- [[$TODAY-kickoff]]
EOF
  echo "==> memory/live-notes/roadmap.md created"
fi

# kickoff decision skeleton
TODAY="$(date +%Y-%m-%d)"
KICKOFF="memory/decisions/$TODAY-kickoff.md"
if [ ! -f "$KICKOFF" ]; then
  PROJECT_NAME="$(basename "$PROJECT_DIR")"
  cat > "$KICKOFF" <<EOF
# Kickoff — $PROJECT_NAME

Chose **<approach>** over **<alternative>** because **<reason>**.

## Context
<what problem this solves>

## Constraints
- <budget / time / stack>

## Related
- [[roadmap]]
EOF
  echo "==> $KICKOFF created — fill in before first real session"
fi

# Obsidian vault marker (opens this folder as vault without re-prompting)
mkdir -p .obsidian
[ -f .obsidian/app.json ] || echo '{"attachmentFolderPath":"memory/inbox"}' > .obsidian/app.json

# .gitignore guards
touch .gitignore
for pat in "memory/inbox/" ".memkraft/" ".rtk/tee/" ".obsidian/workspace*" ".obsidian/cache"; do
  grep -qxF "$pat" .gitignore || echo "$pat" >> .gitignore
done

# memkraft index so search picks up new files
PYTHONUTF8=1 PYTHONIOENCODING=utf-8 memkraft index 2>/dev/null || true

echo ""
echo "==> project ready."
echo "   Next:"
echo "   1. Edit memory/decisions/$TODAY-kickoff.md  (one-line why)"
echo "   2. Edit memory/live-notes/roadmap.md         (milestones)"
echo "   3. Open this folder in Obsidian as vault (optional, for graph view)"
echo "   4. rtk git add CLAUDE.md memory/ .rtk/ plans/ .obsidian/app.json .gitignore"
echo "      rtk git commit -m \"add claude-token-optimizer scaffold\""
