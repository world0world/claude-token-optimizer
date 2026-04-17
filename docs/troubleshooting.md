# Troubleshooting

## MCP server not registering

Check `~/.claude/settings.json` has `mcpServers` block. Restart Claude Code. Then in Claude:
```
claude mcp list
```

On Windows, MCP commands must be wrapped with `cmd /c ...` — the installer handles this but manual edits may miss it.

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
- `/model` swap mid-session
- MCP server added/removed
- More than 5 minutes idle (TTL expired)
- CLAUDE.md or settings.json edited externally

Fix: don't swap models; keep MCPs static per session; reopen the session if idle past TTL.

## Sonnet is re-asking Opus-level questions

The plan file is probably too thin. Opus should produce decisions, constraints, file list, test strategy — not "here's a feature, go implement it." If Sonnet keeps asking, the plan is under-specified.

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
- Are you mid-session on Opus doing implementation work? Split windows.
- Is caveman actually active? Check transcript for verbose replies.
- Did cache get invalidated recently?
