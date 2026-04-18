# Claude Token Optimizer

Reproducible setup that cuts Claude Code token consumption by **~70%** while preserving output quality. Drop-in installer for Windows / macOS / Linux.

## Philosophy

Token cost has four drivers: **system prompt + tool schemas**, **context file loads**, **model tier (per output token)**, and **thinking budget**. This setup attacks all four.

| Driver | Technique | Typical saving |
|---|---|---|
| Tool output | RTK wrappers (`rtk git`, `rtk pytest`, ...) | 60-90% |
| Claude output | Caveman mode (terse style) | 40-60% |
| Context files | MemKraft (L1 index, on-demand pull) | large on active recall |
| Model tier | **Sub-agent role split** (Opus design / Sonnet impl / Haiku review) | ~55% on output |
| Web search | Gemini CLI MCP via `mcp-caller` / `web-researcher` | variable |
| Thinking | Per-sub-agent effort, not global `alwaysThinking` | ~15% |
| Context compaction | memkraft snapshot/dedup/decay + PreCompact hook | compounds |

## Architecture — single session + sub-agents

```
Main (Opus 4.7, effort medium)
  ├→ architect      (Opus, high)   → plans/*.md, memory/decisions/
  ├→ coder          (Sonnet)       → implements plans, TDD
  ├→ reviewer       (Haiku)        → local diff review
  ├→ mcp-caller     (Haiku)        → gemini / codex MCP calls
  └→ web-researcher (Haiku)        → multi-source web research

Shared state: memkraft + plans/ + git commits
```

Each sub-agent has independent context window — raw tool output doesn't leak back to main.

Details: [`docs/architecture.md`](docs/architecture.md) · [`docs/workflow.md`](docs/workflow.md)

## What this repo ships

```
dotclaude/
├── settings.example.json    # model, effort, hooks, permissions (mcpServers registered via `claude mcp add`)
├── CLAUDE.md                # global agent directives
├── agents/                  # 5 sub-agent definitions
│   ├── architect.md
│   ├── coder.md
│   ├── reviewer.md
│   ├── mcp-caller.md
│   └── web-researcher.md
├── commands/
│   ├── tokenoptimizer.md    # /tokenoptimizer (8 subcommands)
│   └── codex-review.md      # /codex-review (spawn Haiku → Codex MCP)
└── refs/                    # detailed references copied to ~/.claude/refs/

scripts/
├── install.sh               # POSIX / Git Bash / WSL
├── install.ps1              # Windows PowerShell
├── setup-project.sh         # per-project memkraft + filter init
└── verify.sh                # post-install smoke test

rtk/
├── config.example.toml
└── filters-samples/

project-templates/
└── CLAUDE.md                # per-project template

docs/
├── architecture.md
├── cost-analysis.md
├── workflow.md
└── troubleshooting.md
```

## Quick start

### Prerequisites
- Node.js 18+, Python 3.10+, Git
- Claude Code CLI logged in (`claude login`)
- Rust/cargo optional (for RTK)

### Install

```bash
git clone https://github.com/<your-fork>/claude-token-optimizer ~/claude-token-optimizer
cd ~/claude-token-optimizer
bash scripts/install.sh      # or: pwsh scripts/install.ps1 on Windows
bash scripts/verify.sh
```

Installer:
- merges `~/.claude/settings.json` (backup kept)
- writes `~/.claude/CLAUDE.md` (existing preserved as `.optimizer`)
- copies `~/.claude/agents/*.md` — 5 sub-agents
- copies `~/.claude/commands/*.md` — `/tokenoptimizer`, `/codex-review`
- copies `~/.claude/refs/*.md`
- registers MCPs via `claude mcp add` (user scope doesn't load `mcpServers` from settings.json)

Existing files are preserved — new content saved with `.optimizer` suffix for manual merge.

### Per-project setup

```bash
cd /path/to/your/project
bash ~/claude-token-optimizer/scripts/setup-project.sh
```

Adds `./CLAUDE.md`, initializes MemKraft, copies `.rtk/filters.toml` template.

### Auth

```bash
gemini          # Google sign-in (or set GEMINI_API_KEY)
codex           # ChatGPT sign-in (or set OPENAI_API_KEY)
```

## Usage

Inside Claude Code:

```
/tokenoptimizer help         # show all subcommands
/tokenoptimizer verify       # verify tools + MCPs + agents
/tokenoptimizer workflow     # show dispatch flow
/tokenoptimizer compact      # manual context compression
/tokenoptimizer resume       # restore state after /clear
/tokenoptimizer dream        # nightly maintenance

/codex-review                # review HEAD (spawns Haiku → Codex MCP)
/codex-review HEAD~3..HEAD   # review range
/codex-review plans/foo.md   # review impl vs plan
```

Main session dispatches sub-agents automatically per CLAUDE.md rules. See [`docs/workflow.md`](docs/workflow.md).

## What's NOT included

- API keys, conversation history, project names — all generic templates
- Plugin binaries — install via `claude /plugin install <name>`
- Hard-coded model versions — role split is the point

## Cost analysis

30-turn coding task, Claude 4.6/4.7 pricing:

| Setup | Estimated cost |
|---|---|
| Pure Opus, no optimization | ~$6.50 |
| Opus + Sonnet split, no RTK/caveman | ~$3.20 |
| **Full optimizer (this repo)** | **~$1.70** |

Details: [`docs/cost-analysis.md`](docs/cost-analysis.md).

## Credits

- [RTK](https://github.com/rtk-ai/rtk) — tool output compression
- [MemKraft](https://github.com/seojoonkim/memkraft) — compound memory
- [Caveman mode](https://github.com/olivergoodman/caveman) — output style plugin
- [Gemini MCP tool](https://github.com/jamubc/gemini-mcp-tool)
- [OpenAI Codex CLI](https://github.com/openai/codex) — second-opinion review
- [Superpowers](https://github.com/anthropics/claude-code-superpowers)

## License

MIT.
