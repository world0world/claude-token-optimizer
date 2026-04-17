#!/usr/bin/env bash
# Weekly token-savings snapshot. Writes to ~/claude-metrics/<date>.md
set -eu

STAMP=$(date +%Y-%m-%d)
OUT_DIR="$HOME/claude-metrics"
OUT="$OUT_DIR/$STAMP.md"
mkdir -p "$OUT_DIR"

{
  echo "# Claude Token Metrics — $STAMP"
  echo
  echo "## RTK gain"
  if command -v rtk >/dev/null; then
    rtk gain --all 2>&1 | sed 's/^/    /'
    echo
    echo "### Recent session adoption"
    rtk session 2>&1 | head -20 | sed 's/^/    /'
  else
    echo "    rtk not installed"
  fi

  echo
  echo "## MemKraft health"
  if command -v memkraft >/dev/null; then
    PYTHONUTF8=1 memkraft doctor 2>&1 | head -20 | sed 's/^/    /'
  fi

  echo
  echo "## CLAUDE.md size (per-turn cost driver)"
  for f in "$HOME/.claude/CLAUDE.md" "./CLAUDE.md"; do
    if [ -f "$f" ]; then
      b=$(wc -c < "$f")
      t=$((b / 4))
      echo "    $f — $b bytes / ~$t tokens"
    fi
  done

  echo
  echo "## MCP servers (schema cost per turn per session)"
  python -c "
import json, os
s = json.load(open(os.path.expanduser('~/.claude/settings.json'), encoding='utf-8'))
for k in s.get('mcpServers', {}):
    print(f'    - {k}')
" 2>/dev/null || echo "    (settings.json parse failed)"

  echo
  echo "## Notes"
  echo "    - add \`/cost\` output from each session manually below"
  echo "    - compare with prior week in ~/claude-metrics/"
} > "$OUT"

echo "wrote $OUT"
cat "$OUT"
