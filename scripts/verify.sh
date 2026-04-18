#!/usr/bin/env bash
# Post-install smoke test. Non-fatal — reports status of each component.
set +e

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; }

echo "==> Claude Token Optimizer verification"

echo
echo "[external CLIs]"
command -v claude    >/dev/null && pass "claude ($(claude --version 2>&1 | head -1))" || fail "claude missing"
command -v gemini    >/dev/null && pass "gemini ($(gemini --version 2>&1 | head -1))"   || fail "gemini missing"
command -v codex     >/dev/null && pass "codex ($(codex --version 2>&1 | head -1))"     || fail "codex missing"
command -v memkraft  >/dev/null && pass "memkraft ($(memkraft --version 2>&1 | head -1))" || fail "memkraft missing"
command -v rtk       >/dev/null && pass "rtk"       || fail "rtk missing (optional)"

echo
echo "[claude config]"
[ -f "$HOME/.claude/settings.json" ] && pass "settings.json present" || fail "settings.json missing"
[ -f "$HOME/.claude/CLAUDE.md" ]     && pass "CLAUDE.md present"     || fail "CLAUDE.md missing"

echo
echo "[sub-agents]"
for a in architect coder reviewer mcp-caller web-researcher; do
  [ -f "$HOME/.claude/agents/$a.md" ] && pass "agent: $a" || fail "agent missing: $a"
done

echo
echo "[slash commands]"
[ -f "$HOME/.claude/commands/tokenoptimizer.md" ] && pass "/tokenoptimizer" || fail "/tokenoptimizer missing"

echo
echo "[MCP registration]"
python - <<'PY' 2>/dev/null
import json, os, sys
p = os.path.expanduser("~/.claude/settings.json")
try:
    s = json.load(open(p, encoding="utf-8"))
    mcps = list(s.get("mcpServers", {}).keys())
    print(f"  ✓ MCP servers: {mcps}" if mcps else "  ✗ no MCP servers")
except Exception as e:
    print(f"  ✗ settings.json parse error: {e}")
PY

echo
echo "[RTK sanity]"
if command -v rtk >/dev/null; then
  rtk gain 2>/dev/null | head -3 | sed 's/^/    /' || fail "rtk gain failed"
fi

echo
echo "[auth hints]"
{ [ -f "$HOME/.gemini/oauth_creds.json" ] || [ -n "${GEMINI_API_KEY:-}" ]; } && pass "gemini authed" || echo "  ? gemini not authed → run: gemini"
{ [ -f "$HOME/.codex/auth.json" ] || [ -d "$HOME/.codex" ] || [ -n "${OPENAI_API_KEY:-}" ]; } && pass "codex authed" || echo "  ? codex not authed → run: codex"

echo
echo "==> done."
