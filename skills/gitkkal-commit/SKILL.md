---
name: gitkkal-commit
description: Generate and execute high-quality Git commits based on semantic change intent and repository settings. Use when the user asks for `/gitkkal:commit` or `$gitkkal-commit`, optionally provides a free-form hint, wants commit messages in conventional/gitmoji/simple style, or wants changes split into logical commits.
---

# Gitkkal Commit

Analyze changes, prepare coherent commit groups, and create commit messages in configured style.

## Agent-Agnostic Rules

- Do not assume client-specific UI features (forms, plan mode, special slash-command runtime).
- Treat trigger command examples as optional; plain-language requests are equally valid.
- Use a hint-first input model: accept one optional free-form hint string (for example, command tail text).
- Do not require strict named parameters for normal usage.
- If intent/grouping is unclear, ask in plain chat.
- Ask one clear follow-up at a time for unresolved decisions.
- If presenting a multiple-choice question, list choices as standalone lines (`1)`, `2)`, `3)`, ...).
  - Do not use Markdown ordered-list syntax (`1.`, `2.`, ...), and do not prefix question text with list numbers.
  - Restart numbering at `1)` for every question.
- Run Git index-mutating commands sequentially only.
  - Never execute `git add`, `git restore --staged`, `git reset`, `git rm --cached`, or `git commit` in parallel/background jobs.
  - If parallel tool execution is available, use it only for read-only commands (status, diff, log, file inspection).
- On `index.lock` errors, stop immediately and recover safely before retrying.
  - Check whether `.git/index.lock` still exists and whether active Git processes are running.
  - Remove the lock file only when no active Git process is using the repository.
  - Retry the failed staging command once after recovery; if it fails again, report and ask the user.

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
- Use imperative tense and keep subject under 50 chars.
9. Stage files explicitly.
- Use file-by-file `git add <path>`.
- Stage in a single sequential flow (for example, one shell script/loop in one command), not parallel calls.
10. Commit using heredoc message construction.

## Guardrails

- Never run `git add .` or `git add -A`.
- Never run `git commit --amend`; create new commits instead.
- Never include `Co-Authored-By` lines.
- If there are no changes, stop with `No changes to commit.`
- If merge conflicts exist, ask user to resolve before committing.
