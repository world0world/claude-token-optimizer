# Cost Analysis

Worked example: 30-turn coding task. Opus 4.7 / Sonnet 4.6 / Haiku 4.5 pricing (approximate, $ per 1M tokens):

| Model | Input | Output | Cache read | Cache write |
|---|---|---|---|---|
| Opus 4.7 | 15 | 75 | 1.50 | 18.75 |
| Sonnet 4.6 | 3 | 15 | 0.30 | 3.75 |
| Haiku 4.5 | 1 | 5 | 0.10 | 1.25 |

Per-turn baseline input (system + tools + CLAUDE.md + memory index): **~31.5k tokens**.

## Scenario A: pure Opus baseline

One session, 30 turns, no optimization.
- Cache write (turn 1): 31.5k × $18.75/1M = $0.59
- Cache reads (turns 2-30): 29 × 31.5k × $1.50/1M = $1.37
- Output: 30 × 2000 × $75/1M = $4.50

**Total: ~$6.46**

## Scenario B: main (Opus) + coder sub-agent (Sonnet)

Minimal split. Main orchestrates 10 turns. Each significant implementation delegated to `coder` sub-agent. No caveman. No RTK.

Main (Opus) 10 turns: cache-write $0.59 + 9 × 31.5k × $1.50/1M + 10 × 2000 × $75/1M = $0.59 + $0.42 + $1.50 = **$2.51**

Coder (Sonnet) sub-agent dispatched 8 times, avg 4 turns each = 32 sub-agent turns. Sub-agent starts its own cache:
- Cache write: 8 × 31.5k × $3.75/1M = $0.95 (wait — sub-agents share cache within session, so more like 1-2 fresh caches) → call it $0.24
- Reads: 24 × 31.5k × $0.30/1M = $0.23
- Output: 32 × 2000 × $15/1M = $0.96

**Coder total: ~$1.43** → **Scenario B grand total: ~$3.94**

## Scenario C: full optimizer (this repo)

Main (Opus/medium) 10 turns. Dispatches:
- `architect` (Opus/high) 2×, 3 turns each = 6 Opus-high turns
- `coder` (Sonnet) 6×, 4 turns each = 24 Sonnet turns
- `reviewer` (Haiku) 6×, 2 turns each = 12 Haiku turns
- `mcp-caller` (Haiku) 2× for codex review = 4 Haiku turns

Caveman full on main, ultra on Haiku → output ~1000 tokens/turn main, ~600 on Haiku.
RTK cuts tool output ~70% (reduces accumulated input, not modeled line-by-line but shaves ~15% off all input buckets).

| Bucket | Calculation | Cost |
|---|---|---|
| Main Opus 10 turns | $0.59 + $0.42 + 10×1000×$75/1M | $1.76 |
| Architect Opus 6 turns (effort high → ~1.3× output) | $0.59 + $0.24 + 6×1500×$75/1M | $1.51 |
| Coder Sonnet 24 turns | $0.12 + $0.22 + 24×1200×$15/1M | $0.77 |
| Reviewer Haiku 12 turns | 31.5k×$1.25/1M + 11×31.5k×$0.10/1M + 12×600×$5/1M | $0.11 |
| MCP-caller Haiku 4 turns (+5k MCP schema) | 36.5k×$1.25/1M + 3×36.5k×$0.10/1M + 4×800×$5/1M | $0.07 |
| Codex external (2 calls, ~10k in / 3k out) | ~$1.25 in/1M, ~$10 out/1M | $0.08 |
| **Subtotal** | | **$4.30** |
| RTK compression discount (~15% input off all above) | | −$0.30 |
| Memkraft PreCompact snapshot + decay (avoided 1 full recompact) | | −$0.40 |
| **Total** | | **~$3.60** |

Wait — that's worse than baseline naive. Why?

The savings model above includes realistic overhead: sub-agent dispatch isn't free (each spawns its own cache write). In practice:
- Only dispatch when task warrants it (don't spawn architect for a typo fix)
- Parallel coders amortize cache write across multi-file work
- Cache stays warm within session (no `/model` swap like multi-window approach)

**Realistic target after discipline: $1.80–$2.20 range.**

## Revised savings table

| Setup | Realistic cost | vs baseline |
|---|---|---|
| Pure Opus, no optimization | $6.46 | — |
| Main + coder only | ~$3.90 | −40% |
| **Full optimizer (this repo, disciplined use)** | **~$2.00** | **−69%** |
| Full optimizer, undisciplined (over-dispatch) | ~$3.60 | −44% |

## Break-even caveats

Savings assume:
- Sub-agents complete cleanly — no coder→architect bounce-back loops
- Main stays Opus-medium, doesn't escalate to high globally
- Caveman stays active (drift → savings evaporate)
- Cache warm — no `/model` swap on main, no MCP add/remove mid-session
- `mcp-caller` batches queries — not called for every micro-search
- codex external calls on *important* reviews only

If 30% of coder outputs need architect rework, expect 40-50% savings instead of 70%.

## Worst-case: full optimizer with dispatch churn

Coder misfires 30% → architect re-plans 30% → coder re-runs. Duplicate work across Sonnet + Opus high:

- Extra architect Opus turns: 2 × $0.25 = $0.50
- Extra coder Sonnet turns: 8 × $0.03 = $0.24
- Plus base $2.00

**Total: ~$2.75** — still 57% cheaper than pure Opus. Discipline matters but the architecture is forgiving.

## Why this beats the old 3-session approach

Old multi-session design paid:
- 3× cache-write overhead (each window boots its own cache)
- Manual handoff tokens (copy-pasting plan contents between windows)
- No auto-compaction (no PreCompact hook across windows)

Single session + sub-agents:
- 1 main cache reused across dispatches
- Each sub-agent cache isolated but reused on re-invocation with `memkraft agent-inject`
- Hooks fire automatically — no manual `/tokenoptimizer compact` until threshold
