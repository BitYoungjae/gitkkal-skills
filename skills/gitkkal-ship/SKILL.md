---
name: gitkkal-ship
description: Ship changes end-to-end — create a branch first when on the default branch, then run the gitkkal-commit flow and the gitkkal-pr flow. Use when the user asks for `/gitkkal:ship` or `$gitkkal-ship`, says "commit and create a PR", "ship these changes", or "finish this branch", or wants semantic commits and a pull request in a single pass.
---

# Gitkkal Ship

One-shot orchestrator: from any starting state — the default branch, a feature branch without a PR, or one with an open PR — land the work as commits on a proper branch and finish with an up-to-date pull request. It sequences three sibling skills: `gitkkal-branch` (only when needed), `gitkkal-commit`, then `gitkkal-pr`. This skill owns sequencing only; all branch, commit, and PR rules live in the skills it loads.

## Operating Principles

- Accept one optional free-form hint (e.g., command tail text) and forward it to the commit and PR stages as advisory context. The branch name is inferred from the diff, not the hint.
- Plain-language requests are equivalent to slash-command triggers.
- Delegate instead of duplicate: never restate the loaded skills' rules. Why: they are the single source of truth; edits to them propagate here automatically.
- Stay client-agnostic: prefer the host's interactive question or choice tool, fall back to plain chat otherwise.

## Persona

- Stage-minded: finish one stage before starting the next; never interleave commit actions with PR actions.
- Surface the plan before mutating anything — branch name, commit plan, PR go/no-go.
- Stop on cancellation rather than continue with partial state. Why: shipping half of what the user approved creates history and PRs they did not ask for.

## Asking the User

When user input is required (commit plan confirmation, PR go/no-go, ambiguous intent), prefer the host's interactive question or choice tool. Fall back to plain chat otherwise. Ask one focused question at a time and wait for the answer.

In the plain-chat fallback only:
- Render multiple-choice options as standalone numbered lines (`1)`, `2)`, `3)`, ...).
- Skip Markdown ordered-list syntax (`1.`, `2.`); avoid prefixing the question itself with a number.
- Restart numbering at `1)` for every question.

## Loading the Sibling Skills

All skills in this bundle are installed together, so the siblings sit next to this skill's directory.

1. If the host can invoke skills natively (skill tool, slash commands), invoke `gitkkal-branch`, `gitkkal-commit`, and `gitkkal-pr` directly at their stages.
2. Otherwise, read the sibling `SKILL.md` files (`../gitkkal-branch/SKILL.md`, `../gitkkal-commit/SKILL.md`, `../gitkkal-pr/SKILL.md`) and follow each as the governing instructions for its stage.

## Workflow

1. Branch — only on the default branch. If the current branch is `main` or `master`, load `gitkkal-branch` and create a branch from the uncommitted changes before committing anything. Why: the PR stage cannot open a PR from the default branch. On any other branch, skip this step.
2. Commit. Load and follow `gitkkal-commit` end to end, including its commit plan confirmation and index safety rules. Finding nothing to commit is fine — continue; the branch may already hold committed work that needs a PR.
3. Checkpoint. Report the commit subjects that just landed (or that nothing needed committing), then ask one go-ahead before the PR (for example, `1) Create/update PR`, `2) Stop here`). Why: a PR is outward-facing; the user decides what becomes public.
4. Pull request. Load and follow `gitkkal-pr` end to end; it detects whether to create or update and pushes the branch as needed.
5. Report. Commit subjects landed, PR number, URL, and mode (created or updated) — or, in `gitkkal-pr` fallback mode, the generated title/body and commands. If the run stopped before the PR, summarize what landed and say the PR was skipped.

## Guardrails

- When this document and a loaded skill disagree, the loaded skill wins; this document governs sequencing only.
- Run stages strictly in order: every commit landed and verified (`git log -1 --oneline`) before any push or `gh` command.
- If any stage is cancelled — branch name declined, commit plan rejected, or `Stop here` at the checkpoint — stop and report what landed. Never continue with partial state.
- Branch-first never rewrites the default branch. If local commits already sit on `main`/`master`, they end up shared by both branches; say so instead of moving them.
