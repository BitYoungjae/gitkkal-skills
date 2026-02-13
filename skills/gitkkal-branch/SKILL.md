---
name: gitkkal-branch
description: Create semantic Git branch names from code intent and project conventions. Use when the user asks for `/gitkkal:branch` or `$gitkkal-branch`, wants a branch suggestion from current diffs, or wants consistent branch naming like `feat/add-login`.
---

# Gitkkal Branch

Create and checkout a branch name that reflects the change intent.

## Agent-Agnostic Rules

- Do not assume client-specific UI features (forms, plan mode, special slash-command runtime).
- Treat trigger command examples as optional; plain-language requests are equally valid.
- Use a hint-first input model: accept one optional free-form description/hint string.
- Do not require strict named parameters for normal usage.
- If user input is needed, ask in plain chat.
- Ask one clear follow-up at a time for unresolved decisions.
- If presenting a multiple-choice question, use options as standalone lines (`1)`, `2)`, `3)`, ...).
  - Do not use Markdown ordered-list syntax (`1.`, `2.`, ...), and do not prefix question text with list numbers.
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

## Guardrails

- Never include spaces, uppercase, or special characters except `-`.
- Never exceed 50 characters in the slug.
- If the branch already exists, propose a safe alternative (for example suffix number).
- If not a Git repo, stop and report clearly.
