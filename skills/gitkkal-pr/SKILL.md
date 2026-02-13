---
name: gitkkal-pr
description: Create or update GitHub pull requests from the current branch using semantic summaries and test plans. Use when the user asks for `/gitkkal:pr` or `$gitkkal-pr`, optionally provides a free-form hint, wants automated PR title/body generation, or wants existing PR content rewritten after new commits.
---

# Gitkkal PR

Create or refresh a pull request using current branch history and intent.

## Agent-Agnostic Rules

- Do not assume client-specific UI features (forms, plan mode, special slash-command runtime).
- Treat trigger command examples as optional; plain-language requests are equally valid.
- Use a hint-first input model: accept one optional free-form hint string (for example, command tail text).
- Do not require strict named parameters for normal usage.
- Ask follow-up questions in plain chat when base branch or PR focus is unclear.
- Ask one clear follow-up at a time for unresolved decisions.
- If asking the user to choose from multiple options, always render choices as standalone numbered lines (`1)`, `2)`, `3)`, ...).
  - Do not use Markdown ordered-list syntax (`1.`, `2.`, ...), and do not prefix question text with list numbers.
  - Restart numbering at `1)` for every question.

## Input Model

- Optional input: `[hint]`
- Treat hint as advisory context for PR framing (focus, title emphasis, summary wording).
- If hint is absent, infer PR focus from commits and diff.
- If hint conflicts with branch changes, ask one clarification before creating/updating.

## Workflow

1. Resolve repo root and load gitkkal config if present.
2. Capture optional hint input.
- Read user-provided free-form hint if present.
3. Verify GitHub CLI state.
- Run `gh auth status`.
- If unavailable or unauthenticated, switch to fallback mode:
  - generate PR title/body output in markdown,
  - provide exact `gh` commands the user can run later,
  - and do not attempt `gh pr create/edit`.
4. Detect mode.
- In normal mode, run `gh pr view --json number,state` for current branch.
- Open PR => update mode.
- Missing/closed/merged => creation mode.
5. Validate branch safety.
- Disallow PR creation from `main` or `master`.
- Never use `git push --force`.
6. Analyze branch intent.
- Start with commit history and `git diff --stat` from base to `HEAD`.
- Read file-level diffs only when intent is unclear.
- Focus on purpose and impact rather than listing files.
7. Build PR content.
- Keep title under 50 chars, imperative mood.
- Follow configured language (`en` or `ko`) when available.
- Body must include `Summary` and `Test plan` sections.
- If repository PR template exists, follow that structure.
8. Execute action.
- In normal mode:
  - Creation: push branch if needed, then `gh pr create --title ... --body ...`.
  - Update: fully replace existing title/body with `gh pr edit`.
- In fallback mode:
  - return final title/body text and command snippets only.
9. Report resulting PR number, URL, and mode (created or updated).

## Guardrails

- Never include `Co-Authored-By` lines in PR body.
- Never modify merged PRs.
- Never append to stale PR description in update mode; rewrite completely.
- If intent is ambiguous, ask the user for the PR's primary focus.
