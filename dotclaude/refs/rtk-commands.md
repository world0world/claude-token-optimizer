# RTK Commands — Full Reference

Prefix every shell command with `rtk`. Passthrough when no filter exists. Always safe.

## Build & Compile (70-90%)
```
rtk cargo build / check / clippy
rtk tsc                    # TypeScript errors grouped
rtk lint                   # ESLint/Biome grouped
rtk prettier --check       # Files needing format only
rtk next build             # Route metrics
```

## Test (90-99%)
```
rtk cargo test
rtk vitest run
rtk playwright test
rtk pytest
rtk go test
rtk rspec / rake test
rtk test <cmd>             # Generic wrapper
```

## Git (59-80%)
```
rtk git {status, log, diff, show, add, commit, push, pull, branch, fetch, stash, worktree}
```
All subcommands passthrough-compatible.

## GitHub (26-87%)
```
rtk gh pr view <n>
rtk gh pr checks
rtk gh run list
rtk gh issue list
rtk gh api
```

## JS/TS Tooling (70-90%)
```
rtk pnpm {list, outdated, install}
rtk npm run <script>
rtk npx <cmd>
rtk prisma
```

## Lint (75-85%)
```
rtk ruff check
rtk rubocop
rtk golangci-lint run
```

## Infra (75-85%)
```
rtk docker {ps, images, logs, compose ps}
rtk kubectl {get, logs, pods, services}
rtk terraform
rtk make
rtk dotnet
rtk aws {sts, ec2, lambda, logs, cloudformation, dynamodb, iam, s3}
```

## Files & Search (60-75%)
```
rtk ls <path>              # Tree format
rtk read <file>            # Code reading w/ filtering
rtk grep <pattern>         # Grouped by file
rtk find <pattern>         # Grouped by dir
rtk smart <file>           # 2-line heuristic summary
```

## Analysis & Debug (70-90%)
```
rtk err <cmd>              # Errors only
rtk log <file>             # Deduplicated
rtk json <file>            # Structure without values
rtk deps
rtk env
rtk summary <cmd>
rtk diff
```

## Network (65-70%)
```
rtk curl <url>
rtk wget <url>
```

## Meta
```
rtk gain [--history|--daily|--graph|--all|--format json]
rtk session                # Adoption rate
rtk discover [--all --since 7]
rtk proxy <cmd>            # Raw passthrough, tracked
rtk init [-g]              # Install hook (Unix shell only)
```

## Flags
- `-u` / `--ultra-compact` — extra savings, ASCII icons
- `-v / -vv / -vvv` — verbosity
- `RTK_DISABLED=1 <cmd>` — bypass once

## Config
- Global: `~/.config/rtk/config.toml` (POSIX) or `%APPDATA%\rtk\config.toml` (Windows)
- Project: `.rtk/filters.toml` (committed)
- `[tee] mode = "failures"` — save raw on fail, re-read without re-run

## Pipes
- `&&`, `||`, `;` — both sides rewritten
- `|` — only left side (right consumes format)
- `find`/`fd` in pipes never rewritten (xargs incompat)

## Hook (Unix shell only; Windows native falls back to manual prefix)
```
rtk init -g                # install PreToolUse hook
```

## Overall savings
60-90% on common operations.
