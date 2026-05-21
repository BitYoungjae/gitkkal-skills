---
name: gitkkal-branch
description: Create semantic Git branch names from code intent and project conventions. Use when the user asks for `/gitkkal:branch` or `$gitkkal-branch`, wants a branch suggestion from current diffs, or wants consistent branch naming like `feat/add-login`.
---

# Gitkkal Branch

Create and checkout a branch name that reflects the change intent.

## Operating Principles

- Accept one optional free-form description as a hint; named parameters are not required.
- Plain-language requests are equivalent to slash-command triggers.
- Stay client-agnostic: prefer the host's interactive question or choice tool, fall back to plain chat otherwise.

## Persona

- Precise about format: kebab-case ASCII, `[a-z0-9-]`, ≤50 chars.
- Confirm the final name before `git checkout -b`; branch creation is a write action.
- Ask one focused question rather than guess on unclear intent or non-English input. Why: a renamed branch costs more than a one-line question.

## Asking the User

When user input is required (no description argument, unclear intent, non-English input, confirming the branch name, branch already exists), prefer the host's interactive question or choice tool. Fall back to plain chat otherwise. Ask one focused question at a time and wait for the answer.

In the plain-chat fallback only:
- Render multiple-choice options as standalone numbered lines (`1)`, `2)`, `3)`, ...).
- Skip Markdown ordered-list syntax (`1.`, `2.`); avoid prefixing the question itself with a number.
- Restart numbering at `1)` for every question.

## Workflow

1. Resolve repo root and load `{repo_root}/.gitkkal/config.json`.
- If missing, use defaults: `language=en`, `branchPattern=type/description`.
2. Handle user argument.
- If a branch description argument is provided, use it directly and skip diff analysis.
3. If no argument, inspect current changes.
- Run `git status --short`, `git diff`, and `git diff --cached`.
- If there are no changes, ask the user for a short branch description.
4. Infer semantic intent from actual diff content.
- Focus on why the change exists, not file counts.
- If intent is unclear, ask for clarification instead of guessing.
5. Select branch type.
- Use one of these numbered options:
  1) `feat`
  2) `fix`
  3) `refactor`
  4) `docs`
  5) `test`
  6) `style`
  7) `chore`
  8) `perf`
  9) `ci`
6. Build branch slug.
- Require English lowercase kebab-case only.
- Allow only `[a-z0-9-]`.
- Limit length to 50 chars.
- If the user gives non-English text, ask for an English description.
7. Apply naming format.
- `type/description`: `{type}/{slug}`
- `description-only`: `{slug}`
8. Confirm branch name with user and allow custom override.
9. Create the branch with `git checkout -b <branch_name>`.
10. Verify checkout: run `git rev-parse --abbrev-ref HEAD` and report the active branch.

## Guardrails

- Output kebab-case ASCII slugs only (`[a-z0-9-]`, ≤50 chars). Why: branch names round-trip through shells, URLs, and CI configs without escaping.
- If the branch already exists, propose a safe alternative (e.g., suffix number) rather than overwriting.
- If the working directory is not a Git repo, stop and report clearly.
