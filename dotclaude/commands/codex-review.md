---
description: Spawn Haiku subagent to route a Codex MCP code review. Use from Sonnet impl session after a commit. Named codex-review to avoid collision with built-in /review.
allowed-tools: Agent, Bash, Read
---

# /codex-review $ARGUMENTS

Dispatch code review via a **Haiku 4.5** subagent that calls Codex MCP. Returns a verdict + top action items without bloating the main session.

## Arguments
`$ARGUMENTS` — optional target:
- empty → `HEAD` commit
- `HEAD~3..HEAD` → commit range
- `plans/<slug>.md` → implementation vs plan
- `<file_path>` → specific file
- `staged` → staged diff only

## Steps

1. Resolve target. Show the user one line:
   ```bash
   rtk git log --oneline -5
   ```
   Derive a short `<slug>` from target (e.g. commit hash short, plan slug, filename stem).

2. Spawn one subagent:
   ```
   Agent tool:
     subagent_type: general-purpose
     model: haiku
     description: "Codex review <slug>"
     prompt: <see template below>
   ```

3. Prompt template for the Haiku subagent:
   ```
   You are a Haiku 4.5 review router. Caveman style.

   Task: route code review via Codex MCP for target: <TARGET>

   Steps:
   1. Capture the change:
        rtk git show <commit>            # single commit
        rtk git diff <range>             # range
        rtk git diff --staged            # staged
        read <path>                      # file or plan
   2. Call mcp__codex__<tool> with:
        - the diff / file content
        - focus: edge cases, security, perf, API contract stability
        - if plan provided: check alignment (missed requirements?)
   3. Parse Codex response.
   4. Write plans/review-<slug>-<YYYYMMDD>.md with:
        - Verdict: APPROVE | CHANGES_REQUESTED | BLOCKER
        - Action items (each with file:line reference)
        - Dismissed suggestions + why
   5. If architectural concern raised, append entry to memory/decisions/.

   Return (under 200 words):
     - Verdict
     - Top 3 action items (bullets)
     - Review file path

   Rules:
   - Do NOT attempt fixes. Review only.
   - All shell via rtk.
   - Caveman output.
   ```

4. Show the user the subagent's return verbatim + suggest next step:
   - APPROVE → consider merge
   - CHANGES_REQUESTED → address action items in current Sonnet session
   - BLOCKER → stop; surface to Opus design window if design-level issue

## Caveat

Review throttle: call `/review` only on meaningful changes (≥3 files changed OR core path touched). Reviewing every commit wastes Codex API tokens without useful signal.
