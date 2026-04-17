#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "==> Claude Token Optimizer install"
echo "    repo: $REPO_DIR"
echo "    target: $CLAUDE_DIR"

# ---------- OS detect ----------
OS="unknown"
case "$(uname -s)" in
  Linux*)    OS="linux" ;;
  Darwin*)   OS="macos" ;;
  MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
esac
echo "    os: $OS"

# ---------- prerequisites ----------
for bin in node npm python git; do
  command -v "$bin" >/dev/null 2>&1 || { echo "missing: $bin. install first."; exit 1; }
done

# ---------- external CLIs ----------
echo "==> installing global CLIs"
npm install -g @google/gemini-cli @openai/codex

python -m pip install --user --upgrade pipx >/dev/null 2>&1 || pip install --user --upgrade pipx
python -m pipx ensurepath >/dev/null 2>&1 || true
export PATH="$HOME/.local/bin:$PATH"
python -m pipx install --force memkraft

if command -v cargo >/dev/null 2>&1; then
  cargo install rtk-cli || echo "    rtk-cli install failed (non-fatal)"
else
  echo "    cargo missing → skipping RTK install. install Rust to enable RTK."
fi

# ---------- settings.json ----------
mkdir -p "$CLAUDE_DIR"

TMP_SETTINGS="$(mktemp)"
cp "$REPO_DIR/dotclaude/settings.example.json" "$TMP_SETTINGS"

# Patch MCP command arrays per OS
python - <<PY
import json, os, sys
p = os.environ["TMP_SETTINGS"]
with open(p, encoding="utf-8") as f:
    s = json.load(f)
os_name = "$OS"

if os_name == "windows":
    s["mcpServers"]["gemini-cli"] = {"command": "cmd", "args": ["/c", "npx", "-y", "gemini-mcp-tool"]}
    s["mcpServers"]["codex"] = {"command": "cmd", "args": ["/c", "codex", "mcp-server"]}
else:
    s["mcpServers"]["gemini-cli"] = {"command": "npx", "args": ["-y", "gemini-mcp-tool"]}
    s["mcpServers"]["codex"] = {"command": "codex", "args": ["mcp-server"]}

# strip internal comment fields
for k in list(s.keys()):
    if k.startswith("_"):
        del s[k]
for k in list(s["mcpServers"].keys()):
    if k.startswith("_"):
        del s["mcpServers"][k]

with open(p, "w", encoding="utf-8") as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
PY
export TMP_SETTINGS

# Merge with existing settings.json if present, else copy
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  echo "==> merging into existing settings.json (backup: settings.json.bak)"
  cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak"
  python - <<PY
import json, os
existing_path = os.path.expanduser("~/.claude/settings.json")
with open(existing_path, encoding="utf-8") as f:
    existing = json.load(f)
with open(os.environ["TMP_SETTINGS"], encoding="utf-8") as f:
    new = json.load(f)
# shallow merge, new wins on conflicts for env/mcpServers, keep existing permissions additive
existing.setdefault("env", {}).update(new.get("env", {}))
existing.setdefault("mcpServers", {}).update(new.get("mcpServers", {}))
if "permissions" in new:
    allow = set(existing.get("permissions", {}).get("allow", [])) | set(new["permissions"].get("allow", []))
    existing.setdefault("permissions", {})["allow"] = sorted(allow)
with open(existing_path, "w", encoding="utf-8") as f:
    json.dump(existing, f, indent=2, ensure_ascii=False)
PY
else
  cp "$TMP_SETTINGS" "$CLAUDE_DIR/settings.json"
fi
rm -f "$TMP_SETTINGS"

# ---------- CLAUDE.md ----------
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  echo "==> CLAUDE.md exists. saving new rules as CLAUDE.md.optimizer for manual merge."
  cp "$REPO_DIR/dotclaude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.optimizer"
else
  cp "$REPO_DIR/dotclaude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
fi

# ---------- slash commands ----------
mkdir -p "$CLAUDE_DIR/commands"
for f in "$REPO_DIR"/dotclaude/commands/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  target="$CLAUDE_DIR/commands/$name"
  if [ -f "$target" ]; then
    echo "==> command exists: $name (skipping)"
  else
    cp "$f" "$target"
    echo "==> installed command: /$name"
  fi
done

# ---------- refs ----------
mkdir -p "$CLAUDE_DIR/refs"
for f in "$REPO_DIR"/dotclaude/refs/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  target="$CLAUDE_DIR/refs/$name"
  if [ -f "$target" ]; then
    echo "==> ref exists: $name (skipping)"
  else
    cp "$f" "$target"
  fi
done

# ---------- RTK config ----------
if command -v rtk >/dev/null 2>&1; then
  if [ "$OS" = "windows" ]; then
    RTK_CFG_DIR="$APPDATA/rtk"
  else
    RTK_CFG_DIR="$HOME/.config/rtk"
  fi
  mkdir -p "$RTK_CFG_DIR"
  if [ ! -f "$RTK_CFG_DIR/config.toml" ]; then
    cp "$REPO_DIR/rtk/config.example.toml" "$RTK_CFG_DIR/config.toml"
    echo "==> installed RTK config at $RTK_CFG_DIR/config.toml"
  fi
fi

# ---------- plugin install prompts ----------
cat <<EOF

==> next steps (manual)

1. Start Claude Code and install plugins:
     /plugin install caveman
     /plugin install superpowers

2. Auth the helper CLIs:
     gemini          # or set GEMINI_API_KEY
     codex           # or set OPENAI_API_KEY

3. For each project you work in:
     cd /path/to/project
     bash $REPO_DIR/scripts/setup-project.sh

4. Verify:
     bash $REPO_DIR/scripts/verify.sh

EOF
echo "==> done."
