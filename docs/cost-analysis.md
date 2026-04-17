# Cost Analysis

Worked example: 30-turn coding task. Opus 4.7 / Sonnet 4.6 / Haiku 4.5 pricing (approximate, $ per 1M tokens):

| Model | Input | Output | Cache read | Cache write |
|-------|-------|--------|-----------|-------------|
| Opus 4.7 | 15 | 75 | 1.50 | 18.75 |
| Sonnet 4.6 | 3 | 15 | 0.30 | 3.75 |
| Haiku 4.5 | 1 | 5 | 0.10 | 1.25 |

Per-turn baseline input (system + tools + CLAUDE.md + MEMORY.md): **~31.5k tokens**.

## Scenario A: pure Opus baseline

One session, 30 turns, no optimization.
- Cache write (turn 1): 31.5k × $18.75/1M = $0.59
- Cache reads (turns 2-30): 29 × 31.5k × $1.50/1M = $1.37
- Output: 30 × 2000 × $75/1M = $4.50

**Total: ~$6.46**

## Scenario B: two-session split (Opus design + Sonnet implement)

Turns split 6 Opus / 24 Sonnet. No caveman. Default output ~2000 tokens/turn.

Opus 6 turns: first-turn write $0.59 + 5 × 31.5k × $1.50/1M + 6 × 2000 × $75/1M = $0.59 + $0.24 + $0.90 = **$1.73**

Sonnet 24 turns: 31.5k × $3.75/1M + 23 × 31.5k × $0.30/1M + 24 × 2000 × $15/1M = $0.12 + $0.22 + $0.72 = **$1.06**

**Total: ~$2.79**

## Scenario C: full optimizer (this repo)

Turns split 6 Opus / 18 Sonnet / 6 Haiku. Caveman cuts output to ~1000 tokens/turn. RTK cuts tool output ~70% (indirect, not modeled here). MemKraft template adds negligible overhead.

Opus 6 turns: $0.59 + $0.24 + 6 × 1000 × $75/1M = $0.59 + $0.24 + $0.45 = **$1.28**

Sonnet 18 turns: 31.5k × $3.75/1M + 17 × 31.5k × $0.30/1M + 18 × 1000 × $15/1M = $0.12 + $0.16 + $0.27 = **$0.55**

Haiku 6 turns (with gemini+codex MCP ~+5k schema → 36.5k input): 36.5k × $1.25/1M + 5 × 36.5k × $0.10/1M + 6 × 800 × $5/1M = $0.046 + $0.018 + $0.024 = **$0.09**

Codex (GPT-5) review calls from Haiku: 2 × (~10k input + 3k output) at approx $1.25 input / $10 output per 1M = **~$0.08**

**Total: ~$2.00**

Additional savings not modeled:
- RTK tool output compression (can shave 10-20% more off input across the board)
- Gemini search (replaces WebFetch with external billable — neutral to slightly positive)
- MemKraft L1 vs full MEMORY.md load (marginal)

Realistic target: **$1.60–$2.00 range** for the full optimizer.

## Savings

| Setup | Cost | vs baseline |
|-------|------|-------------|
| Pure Opus | $6.46 | — |
| Two-session split | $2.79 | −57% |
| Full optimizer | ~$1.80 | **−72%** |

## Break-even caveats

Savings assume:
- Sonnet completes tasks without needing Opus rescue. If 30% of Sonnet turns require Opus re-work, savings collapse toward the baseline.
- Caveman mode stays consistent across the session (drift → savings evaporate).
- Cache stays warm (no `/model` mid-session, no MCP toggle, no long idle periods).
- Codex is called on *important* commits only. Calling it every commit doubles the Haiku cost bucket.

If any assumption breaks, expect 30-50% savings instead of 70%.

## Worst-case: full optimizer with drift

Sonnet misfires 40% of implementations → Opus redoes 40% of session 2 turns:

- Opus extra: 7 redo-turns × $0.20 = $1.40
- Plus base $2.00

**Total: $3.40** — still 48% cheaper than pure Opus, but the margin narrows. Discipline matters.
