# Claude Token Optimizer

A reproducible setup that cuts Claude Code token consumption by **~70%** while preserving output quality. Drop-in installer for new machines (Windows / macOS / Linux).

## Philosophy

Token cost has four drivers: **system prompt + tool schemas (per turn)**, **context file loads (per turn)**, **model tier (per output token)**, and **thinking budget (per reasoning token)**. This setup attacks all four.

| Driver | Technique | Typical saving |
|--------|-----------|---------------|
| Tool output | RTK wrappers (`rtk git`, `rtk pytest`, ...) | 60-90% |
| Claude output | Caveman mode (terse style) | 40-60% |
| Context files | MemKraft template (L1 index, on-demand pull) vs loading everything | ~5% idle, huge on active recall |
| Model tier | Multi-session role split (Opus design / Sonnet implement / Haiku orchestrate) | ~55% on output |
| Search | Gemini CLI MCP instead of in-process search | variable |
| Thinking | Per-session effort, not global `alwaysThinking` | ~15% |

## Architecture at a glance

```
Session 1 (Opus 4.7, high)   →  designs, writes plans/*.md, reviews diffs
Session 2 (Sonnet 4.6, med)  →  implements plans, spawns parallel Sonnet subagents
Session 3 (Haiku 4.5, low)   →  routes work: calls Codex MCP for review, Gemini MCP for search
           ↓                              ↓                            ↓
           └─────── shared MemKraft memory/ (template mode, no MCP) ──┘
                         (same project folder = same memory)
```

See [`docs/architecture.md`](docs/architecture.md) for full rationale.

## What this repo ships

```
dotclaude/
├── settings.example.json      # Sanitized global settings (MCP, env, permissions)
├── CLAUDE.md                  # Global rules: session architecture + RTK + search
├── commands/                  # Slash commands (copied to ~/.claude/commands/)
│   ├── tokenoptimizer.md      # /tokenoptimizer — per-project scaffold
│   └── review.md              # /review — Haiku→Codex review from Sonnet session
├── refs/                      # Detailed references (copied to ~/.claude/refs/)
│   ├── rtk-commands.md
│   ├── superpowers.md
│   ├── cache-awareness.md
│   ├── self-improvement.md
│   └── file-system-as-state.md
└── memory/                    # Optional global memory scaffold

scripts/
├── install.sh                 # POSIX / Git Bash / WSL installer
├── install.ps1                # Windows PowerShell installer
├── setup-project.sh           # Per-project MemKraft + filter init
└── verify.sh                  # Post-install smoke test

rtk/
├── config.example.toml        # Global RTK config (tee mode, excludes)
└── filters-samples/           # Drop-in .rtk/filters.toml templates

project-templates/
└── CLAUDE.md                  # Example per-project override

docs/
├── architecture.md            # 3-session role split reasoning
├── cost-analysis.md           # Math showing ~70% savings
├── workflow.md                # Daily routines
└── troubleshooting.md
```

## Quick start

### Prerequisites
- Node.js 18+
- Python 3.10+
- Git
- Claude Code CLI logged in (`claude login`)

### Install

```bash
git clone https://github.com/<your-fork>/claude-token-optimizer ~/claude-token-optimizer
cd ~/claude-token-optimizer
bash scripts/install.sh        # or: pwsh scripts/install.ps1 on Windows
bash scripts/verify.sh
```

### Per-project setup

```bash
cd /path/to/your/project
bash ~/claude-token-optimizer/scripts/setup-project.sh
```

This adds a local `./CLAUDE.md`, initializes MemKraft memory, and copies a `.rtk/filters.toml` template.

### Auth the helper CLIs

```bash
gemini                         # Google sign-in (or set GEMINI_API_KEY)
codex                          # ChatGPT sign-in (or set OPENAI_API_KEY)
```

## Two-window hybrid workflow (recommended)

Managing three windows manually is tedious. The refined pattern uses **two** persistent windows plus on-demand subagents:

| Window | `/model` | effort | Role |
|--------|---------|--------|------|
| 1 | opus | high | Design, `plans/*.md`, architecture review |
| 2 | sonnet | medium | Implementation. Calls `/review` to spawn a Haiku subagent that routes Codex MCP |

From the Sonnet window:
```
/review              # review HEAD
/review HEAD~3..HEAD # review range
/review plans/foo.md # review impl vs plan
```

A Haiku subagent spawns, calls `mcp__codex__review`, writes `plans/review-*.md`, returns a 200-word summary. No third window, no manual dispatch.

### Legacy three-window layout

Still valid if you prefer isolated caches per role:

| Window | `/model` | effort | Role |
|--------|---------|--------|------|
| 1 | opus | high | Design |
| 2 | sonnet | medium | Implementation |
| 3 | haiku | low | Codex review, web search orchestration |

Windows share state via:
- `plans/*.md` — design handoff
- `memory/` (MemKraft) — facts, decisions, entities
- `git` commits — canonical source of truth

Full routine in [`docs/workflow.md`](docs/workflow.md).

## What's NOT included

- Personal API keys, conversation history, project names — all generic templates
- Plugin binaries — install via `claude /plugin install <name>`
- Model names hardcoded — the role split is the point, not specific version numbers

## Cost analysis

30-turn coding task, Claude 4.6/4.7 pricing:

| Setup | Estimated cost |
|-------|---------------|
| Pure Opus, no optimization | ~$6.50 |
| Opus + Sonnet split, no RTK/caveman | ~$3.20 |
| **Full optimizer (this repo)** | **~$1.70** |

Details in [`docs/cost-analysis.md`](docs/cost-analysis.md).

## Credits

- [RTK (Rust Token Killer)](https://github.com/rtk-ai/rtk) — tool output compression
- [MemKraft](https://github.com/seojoonkim/memkraft) — compound memory
- [Caveman mode](https://github.com/olivergoodman/caveman) — output style plugin
- [Gemini MCP tool](https://github.com/jamubc/gemini-mcp-tool)
- [OpenAI Codex CLI](https://github.com/openai/codex) — second-opinion review
- [Superpowers](https://github.com/anthropics/claude-code-superpowers) — workflow skills

## License

MIT. Do what you want.
