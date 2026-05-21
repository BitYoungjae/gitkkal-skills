---
name: gitkkal-commit
description: Generate and execute high-quality Git commits based on semantic change intent and repository settings. Use when the user asks for `/gitkkal:commit` or `$gitkkal-commit`, optionally provides a free-form hint, wants commit messages in conventional/gitmoji/simple style, or wants changes split into logical commits.
---

# Gitkkal Commit

Analyze changes, prepare coherent commit groups, and create commit messages in configured style.

## Operating Principles

- Accept one optional free-form hint (e.g., command tail text); treat as advisory, not a hard constraint.
- Plain-language requests are equivalent to slash-command triggers.
- Stay client-agnostic: prefer the host's interactive question or choice tool, fall back to plain chat otherwise.

## Persona

- Methodical: surface the commit plan before staging, then execute it.
- When hint conflicts with code evidence, ask one clarification rather than override the diff. Why: commits become permanent history.
- Treat the Git index as shared state — mutations are sequential, never parallel.

## Index Safety

- Run Git index-mutating commands sequentially only.
- `git add`, `git restore --staged`, `git reset`, `git rm --cached`, and `git commit` must not run in parallel or background jobs.
- Parallel tool execution is fine for read-only commands (status, diff, log, file inspection).
- On `index.lock` errors, stop immediately and recover safely before retrying.
- Check whether `.git/index.lock` still exists and whether active Git processes are running.
- Remove the lock file only when no active Git process is using the repository.
- Retry the failed staging command once after recovery; if it fails again, report and ask the user.

Why: Git's index is a single shared file. Concurrent mutations corrupt it; sequential staging avoids that class of failure cheaply.

## Asking the User

When user input is required (unclear intent, unclear commit grouping, confirming the commit plan), prefer the host's interactive question or choice tool. Fall back to plain chat otherwise. Ask one focused question at a time and wait for the answer.

In the plain-chat fallback only:
- Render multiple-choice options as standalone numbered lines (`1)`, `2)`, `3)`, ...).
- Skip Markdown ordered-list syntax (`1.`, `2.`); avoid prefixing the question itself with a number.
- Restart numbering at `1)` for every question.

## Input Model

- Optional input: `[hint]`
- Treat hint as advisory context, not hard constraints.
- If hint is absent, infer intent from diffs and commit history.
- If hint conflicts with code evidence, ask one clarification before committing.

## Workflow

1. Resolve repo root and load `{repo_root}/.gitkkal/config.json`.
- If missing, use defaults: `language=en`, `commitPattern=conventional`, `splitCommits=true`, `askOnAmbiguity=true`.
2. Capture optional hint input.
- Read user-provided free-form hint if present.
3. Gather change context.
- Run `git status --short`, `git diff --cached`, `git diff`, and `git log --oneline -5`.
4. Exclude sensitive files from candidate staging.
- Exclude secrets like `.env`, credential files, private keys, tokens.
5. Infer semantic intent from code changes.
- Focus on why the change exists.
- Use the optional hint as additional guidance.
- If intent is unclear and `askOnAmbiguity=true`, ask before committing.
6. Decide commit splitting.
- If `splitCommits=true`, split by cohesive logical units.
- Keep each commit independently understandable.
7. Present the commit plan before execution.
- Show commit groups and proposed commit subjects.
- Ask for user confirmation before staging and committing using numbered options (for example, `1) Proceed`, `2) Edit plan`, `3) Cancel`).
8. Compose commit messages.
- `conventional`: `<type>[(scope)]: <description>`
- `gitmoji`: `<emoji> <description>`
- `simple`: `<description>`
- Use imperative tense; cap subject at 50 chars.
9. Stage files explicitly.
- Use file-by-file `git add <path>`.
- Stage in a single sequential flow (one shell script/loop in one command), never parallel calls.
10. Commit using heredoc message construction.
11. Verify: run `git log -1 --oneline` after each commit and report the subjects that landed.

## Guardrails

- Stage explicit paths only. Why: `git add .` and `git add -A` can sweep in `.env` or generated files no one wanted in history.
- Create new commits rather than amending. Why: amend rewrites history; new commits are reversible.
- Skip `Co-Authored-By` lines in messages.
- If there are no changes, stop with `No changes to commit.`
- If merge conflicts exist, ask the user to resolve before committing.
