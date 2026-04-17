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

# .gitignore guards
touch .gitignore
for pat in "memory/inbox/" ".memkraft/" ".rtk/tee/"; do
  grep -qxF "$pat" .gitignore || echo "$pat" >> .gitignore
done

echo "==> project ready. commit:"
echo "     rtk git add CLAUDE.md memory/ .rtk/ plans/"
echo "     rtk git commit -m \"add claude-token-optimizer scaffold\""
