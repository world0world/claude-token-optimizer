# Troubleshooting

## MCP server not registering

User-scope `settings.json` does **not** load `mcpServers` — register via CLI:
```bash
claude mcp add gemini-cli -s user -- npx -y gemini-mcp-tool
claude mcp add codex -s user -- codex mcp-server
# Windows (git-bash):
MSYS_NO_PATHCONV=1 claude mcp add gemini-cli -s user -- cmd /c npx -y gemini-mcp-tool
MSYS_NO_PATHCONV=1 claude mcp add codex -s user -- cmd /c codex mcp-server
```
Then `claude mcp list` to verify. `install.sh` does this automatically.

## `memkraft init` fails with UnicodeEncodeError on Windows

Set UTF-8 env:
```bash
export PYTHONUTF8=1
export PYTHONIOENCODING=utf-8
```

The installer adds these to `settings.json` env, but CLI invocations outside Claude Code need them in the shell.

## RTK hook not firing

Windows native Claude Code does not execute the RTK PreToolUse hook (Unix shell required). Fall back to manual prefixing via the CLAUDE.md rule. WSL users: `rtk init -g` installs the hook.

## Caveman mode drifts back to normal

Re-invoke with `/caveman full` or `/caveman ultra`. If it drifts repeatedly mid-session, you likely hit a context reset — check if `/model` or an MCP toggle triggered a cache reset.

## Cache miss every turn

Signs: first-turn-like latency, cost higher than expected. Causes:
- `/model` swap on main session
- MCP server added/removed mid-session
- More than 5 minutes idle (TTL expired)
- CLAUDE.md or settings.json edited externally
- Agent md file edited — that sub-agent's cache invalidates

Fix: don't swap main model; keep MCPs static; reopen the session if idle past TTL; batch agent md edits before a fresh session.

## Coder sub-agent bounces plan back

The plan file is probably too thin. `architect` should produce decisions, constraints, file list, test strategy — not "here's a feature, go implement it." If `coder` keeps returning "plan thin, need architect amendment", the plan is under-specified. Re-dispatch architect with specific gaps listed.

## Codex MCP review returns garbage

Codex CLI needs auth:
```bash
codex    # interactive login, or:
export OPENAI_API_KEY=sk-...
```
Test separately: `codex --help`. If it works outside Claude Code, the MCP invocation should work too.

## Settings changes not applying

Claude Code reads `settings.json` on startup. Fully restart the CLI, not just the session window.

## Project-local settings not picked up

`.claude/settings.local.json` inside a project folder applies only when Claude Code is launched from that folder. `cd` into the project first, then start Claude Code.

## MemKraft search returns nothing

Check:
```bash
memkraft doctor
ls memory/entities/
```
Empty memory = nothing to find. Write at least one entity or decision to test search.

## Gemini MCP search times out

Gemini CLI needs either:
- Interactive login (`gemini` once)
- `GEMINI_API_KEY` env var

And an active network connection. Behind corporate proxies, set `HTTPS_PROXY`.

## Permission prompts every command

Add the command to `permissions.allow` in `~/.claude/settings.json`:
```json
"permissions": {
  "allow": ["Bash(rtk:*)", "Bash(pytest:*)"]
}
```

## High cost despite optimizer

Diagnose with the token-diet skill (or inspect manually):
- Is effortLevel=high set globally? Move to per-project.
- Is alwaysThinkingEnabled=true? Same.
- Is main doing mechanical edits itself? Dispatch `coder` sub-agent instead.
- Is every small task dispatching a sub-agent? Over-dispatch → cache-write churn. Handle trivial stuff inline on main.
- Is caveman actually active? Check transcript for verbose replies.
- Did cache get invalidated recently?
