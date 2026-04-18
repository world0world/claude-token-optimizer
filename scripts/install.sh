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

# Strip internal comment fields and any mcpServers block (user-scope settings.json doesn't load mcpServers)
python - <<PY
import json, os
p = os.environ["TMP_SETTINGS"]
with open(p, encoding="utf-8") as f:
    s = json.load(f)
s.pop("mcpServers", None)
for k in list(s.keys()):
    if k.startswith("_"):
        del s[k]
with open(p, "w", encoding="utf-8") as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
PY
export TMP_SETTINGS

# Register MCPs via claude CLI (settings.json mcpServers is ignored at user scope)
if command -v claude >/dev/null 2>&1; then
  echo "==> registering MCP servers via claude mcp add"
  if [ "$OS" = "windows" ]; then
    MSYS_NO_PATHCONV=1 claude mcp add gemini-cli -s user -- cmd /c npx -y gemini-mcp-tool 2>/dev/null || echo "    gemini-cli already registered"
    MSYS_NO_PATHCONV=1 claude mcp add codex -s user -- cmd /c codex mcp-server 2>/dev/null || echo "    codex already registered"
  else
    claude mcp add gemini-cli -s user -- npx -y gemini-mcp-tool 2>/dev/null || echo "    gemini-cli already registered"
    claude mcp add codex -s user -- codex mcp-server 2>/dev/null || echo "    codex already registered"
  fi
else
  echo "    claude CLI not found → register MCPs manually after install"
fi

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
existing.setdefault("env", {}).update(new.get("env", {}))
if "permissions" in new:
    allow = set(existing.get("permissions", {}).get("allow", [])) | set(new["permissions"].get("allow", []))
    existing.setdefault("permissions", {})["allow"] = sorted(allow)
# top-level scalars — only set if not present, don't clobber user choice
for k in ("model", "effortLevel", "autoUpdatesChannel"):
    if k in new and k not in existing:
        existing[k] = new[k]
# hooks — per-event, new wins per event if event not in existing
if "hooks" in new:
    existing.setdefault("hooks", {})
    for event, handlers in new["hooks"].items():
        if event not in existing["hooks"]:
            existing["hooks"][event] = handlers
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

# ---------- sub-agents ----------
mkdir -p "$CLAUDE_DIR/agents"
for f in "$REPO_DIR"/dotclaude/agents/*.md; do
  [ -f "$f" ] || continue
  name="$(basename "$f")"
  target="$CLAUDE_DIR/agents/$name"
  if [ -f "$target" ]; then
    cp "$f" "$target.optimizer"
    echo "    agent exists: $name → saved as $name.optimizer"
  else
    cp "$f" "$target"
    echo "    installed agent: $name"
  fi
done

# ---------- slash commands ----------
mkdir -p "$CLAUDE_DIR/commands"
for f in "$REPO_DIR"/dotclaude/commands/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  target="$CLAUDE_DIR/commands/$name"
  if [ -f "$target" ]; then
    cp "$f" "$target.optimizer"
    echo "==> command exists: $name → saved as $name.optimizer"
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
    echo "==> installed ref: $name"
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
