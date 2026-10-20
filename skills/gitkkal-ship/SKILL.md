---
name: gitkkal-ship
description: Ship changes end-to-end by running the gitkkal-commit flow and then the gitkkal-pr flow. Use when the user asks for `/gitkkal:ship` or `$gitkkal-ship`, says "commit and create a PR", "ship these changes", or "finish this branch", or wants semantic commits and a pull request in a single pass.
---

# Gitkkal Ship

One-shot orchestrator: load `gitkkal-commit`, land the commits, then load `gitkkal-pr`, open or update the pull request. This skill owns sequencing only — all commit and PR rules live in the two skills it loads.

## Operating Principles

- Accept one optional free-form hint (e.g., command tail text); forward it to both stages as advisory context.
- Plain-language requests are equivalent to slash-command triggers.
- Delegate instead of duplicate: never restate or paraphrase the loaded skills' rules. Why: they are the single source of truth; edits to them propagate here automatically.
- Stay client-agnostic: prefer the host's interactive question or choice tool, fall back to plain chat otherwise.

## Persona

- Stage-minded: run one stage at a time to completion; never interleave commit staging with PR actions.
- Surface the plan before mutating anything (commit plan first, PR content second).
- Stop on cancellation rather than continue with partial state. Why: shipping half of what the user approved creates history and PRs they did not ask for.

## Asking the User

When user input is required (commit plan confirmation, PR go/no-go, ambiguous intent), prefer the host's interactive question or choice tool. Fall back to plain chat otherwise. Ask one focused question at a time and wait for the answer.

In the plain-chat fallback only:
- Render multiple-choice options as standalone numbered lines (`1)`, `2)`, `3)`, ...).
- Skip Markdown ordered-list syntax (`1.`, `2.`); avoid prefixing the question itself with a number.
- Restart numbering at `1)` for every question.

## Input Model

- Optional input: `[hint]`
- Forward the same hint to both stages as advisory context (commit intent, then PR framing).
- If hint is absent, each stage infers intent from git state per its own workflow.

## Loading the Sibling Skills

This skill runs `gitkkal-commit` and `gitkkal-pr`; all skills in this bundle are always installed together, so the siblings are present next to this skill's directory.

1. If the host supports invoking skills natively (skill tool, slash commands), invoke `gitkkal-commit` and `gitkkal-pr` directly at their stages.
2. Otherwise, read the sibling `SKILL.md` files next to this skill's directory (`../gitkkal-commit/SKILL.md` and `../gitkkal-pr/SKILL.md`) and follow each as the governing instructions for its stage.

## Workflow

1. Resolve repo root and load `{repo_root}/.gitkkal/config.json`.
- If missing, use defaults: `language=en`, `commitPattern=conventional`, `splitCommits=true`, `askOnAmbiguity=true`.
2. Stage 1 — Commit. Load and follow `gitkkal-commit` end to end, including its commit plan confirmation and index safety rules.
- If the user cancels the commit plan, stop the whole run. Do not proceed to the PR stage.
- If there are no changes to commit, report it and continue to Stage 2 — the branch may still hold committed work that needs a PR.
3. Checkpoint — confirm the PR stage.
- Report the commit subjects that just landed.
- Ask whether to proceed to the pull request using numbered options (for example, `1) Create/update PR`, `2) Stop here`).
- Opening a PR is an outward-facing action; one explicit go-ahead here keeps the user in control of what becomes public.
4. Stage 2 — Pull request. Load and follow `gitkkal-pr` end to end, forwarding the original hint.
5. Final report. Summarize both stages: commit subjects landed, PR number, URL, and mode (created or updated). In fallback mode, report the generated PR title/body and commands instead.

## Guardrails

- Never duplicate sibling rules. When this document and a loaded skill disagree on commit or PR mechanics, the loaded skill wins; this document governs sequencing only.
- Run stages sequentially: finish all commits (including the `git log -1 --oneline` verification each one requires) before any push or `gh` command.
- If the commit stage is cancelled, never create a PR from the partial state.
- Respect each stage's own clarification behavior (`askOnAmbiguity`, hint-versus-diff conflicts).
