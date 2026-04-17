# Global Claude Code Rules

## RTK — Token-Optimized Command Wrappers

**Always prefix shell commands with `rtk`.** RTK compresses tool output 60-90%. Works as a passthrough when no dedicated filter exists, so it is always safe.

Even inside chains:
```bash
# Wrong
git add . && git commit -m "msg" && git push

# Right
rtk git add . && rtk git commit -m "msg" && rtk git push
```

### Most-used wrappers

| Category | Commands |
|----------|----------|
| Git | `rtk git {status,log,diff,add,commit,push,pull,branch,fetch,stash,worktree}` |
| GitHub | `rtk gh {pr view,pr checks,run list,issue list,api}` |
| Build | `rtk {cargo build,cargo check,cargo clippy,tsc,lint,next build,prettier --check}` |
| Test | `rtk {cargo test,vitest run,playwright test,pytest,go test,rspec,test <cmd>}` |
| JS/TS | `rtk {pnpm list,pnpm install,npm run <s>,npx <cmd>,prisma}` |
| Lint | `rtk {ruff check,rubocop,golangci-lint run}` |
| Infra | `rtk {docker ps,docker images,docker logs,kubectl get,kubectl logs,terraform,make,dotnet}` |
| AWS | `rtk aws {sts,ec2,lambda,logs,cloudformation,dynamodb,iam,s3}` |
| Files | `rtk {ls,read,grep,find,smart <file>}` |
| Debug | `rtk {err,log,json,deps,env,summary,diff}` |
| Network | `rtk {curl,wget}` |
| Meta | `rtk {gain,session,discover,proxy,init}` |

Flags: `-u` / `--ultra-compact` for extra savings. `RTK_DISABLED=1 <cmd>` to bypass once.

Typical savings: **60-90%** on common operations.

## Web Search Routing

For Google / web search, prefer **Gemini CLI MCP tools** (`mcp__gemini-cli__*`) over the built-in WebSearch/WebFetch. Gemini grounds searches at lower marginal cost.

## Multi-Session Convention

This machine runs up to three parallel Claude Code windows per project:

1. **Opus** — design, plans, review
2. **Sonnet** — implementation, parallel subagents
3. **Haiku** — orchestration, Codex review, search

All three share state through:
- `plans/*.md` (design docs)
- `memory/` (MemKraft store)
- `git` commits

Never change `/model` mid-session (breaks prompt cache).

## Caveman Output Style

Output is compressed: drop articles, fragments OK, technical terms exact. Code blocks unchanged. Quoted errors exact. See caveman plugin for details.

## MemKraft Memory

Projects with a `./memory/` directory use MemKraft template mode. Store decisions in `memory/decisions/`, entities in `memory/entities/`, session notes in `memory/sessions/`. Search via `memkraft search <term>`.
