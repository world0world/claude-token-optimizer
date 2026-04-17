# Superpowers — Skill Usage

Superpowers plugin bundles workflow skills. Invoke via `Skill` tool.

## Priority order

1. **Process skills first** (brainstorming, debugging) — determine HOW
2. **Implementation skills second** (frontend-design, mcp-builder) — guide execution

"Build X" → brainstorming first, then implementation skills.
"Fix bug" → debugging first, then domain skills.

## Key skills

| Skill | Use when |
|-------|---------|
| `brainstorming` | Any creative work before touching files |
| `writing-plans` | Spec → plan, before implementation |
| `executing-plans` | Written plan exists, separate session |
| `test-driven-development` | Any feature/bugfix, before impl code |
| `systematic-debugging` | Bug/failure/unexpected behavior |
| `dispatching-parallel-agents` | 2+ independent tasks, no shared state |
| `subagent-driven-development` | Plan execution in current session |
| `verification-before-completion` | Before claiming "done" |
| `requesting-code-review` | Major feature complete, pre-merge |
| `receiving-code-review` | Responding to review feedback |
| `finishing-a-development-branch` | All tests pass, decide merge path |
| `using-git-worktrees` | Feature work needing isolation |
| `writing-skills` | Create/edit skills |

## Invocation rule

If 1% chance a skill applies → invoke. Don't rationalize out.

Red flags (stop, invoke):
- "This is just a simple question"
- "Let me explore codebase first"
- "I remember this skill"
- "The skill is overkill"

## Skill types

- **Rigid** (TDD, debugging): follow exactly
- **Flexible** (patterns): adapt principles

Skill itself states which.

## User instructions override

CLAUDE.md / AGENTS.md / user's direct request > superpowers skill > default system prompt.

User says "skip TDD" → skip. Skill says "always TDD" → yield.
