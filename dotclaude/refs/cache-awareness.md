# Prompt Cache Awareness

Anthropic prompt cache: first cache write 1.25× input cost, subsequent reads 0.10× input cost. 90% discount when hit.

## What counts as cached prefix
- System prompt
- Tool schemas (all MCP + built-in)
- CLAUDE.md + per-project CLAUDE.md
- Memory files auto-loaded

Anything before Claude's reply in the conversation.

## What breaks cache (full re-write)
- `/model` switch mid-session
- MCP server add/remove
- `settings.json` edit (ext)
- CLAUDE.md edit while session running
- Tool schema change (plugin install)
- Idle > 5 min (Pro/default TTL); > 1 hr (subscription extended)

## Cost of a cache miss
~12× the hit cost. 31.5k token prefix: hit = $0.047, miss = $0.59. One unnecessary `/model` swap on Opus ≈ $0.55.

## Habits

- Decide model per window BEFORE opening. No mid-session swap.
- Install MCPs before starting real work.
- Edit CLAUDE.md between sessions, not during.
- Keep sessions warm: don't idle past TTL mid-task; send trivial ping if needed.
- Long work → split into focused sessions, each with consistent config.

## TTL extension
Subscription plans extend to 1 hr. Free/pay-as-you-go = 5 min.

## Diagnosing cache issues
- `/cost` shows `Cache read` vs `Cache creation input`. High creation → cache breaking often.
- Sudden latency spike on turn = cache miss.

## When to accept a cache miss
- New project kickoff (unavoidable)
- Major config change (one-time pain)
- Switching to appropriate cheaper model mid-task (rare; usually split sessions instead)
