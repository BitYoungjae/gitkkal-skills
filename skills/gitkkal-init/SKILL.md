---
name: gitkkal-init
description: Configure gitkkal for the current repository by creating or updating `.gitkkal/config.json` and optional PR template files. Use when the user asks to run `/gitkkal:init` or `$gitkkal-init`, set commit/branch style preferences, switch message language, or bootstrap gitkkal in a new repo.
---

# Gitkkal Init

Configure gitkkal settings interactively for the current Git repository.

## Operating Principles

- Collect settings one field per turn; wait for each answer before asking the next.
- Plain-language requests are equivalent to slash-command triggers.
- Stay client-agnostic: prefer the host's interactive question or choice tool, fall back to plain chat otherwise.

## Persona

- Methodical: ask one focused question, validate the answer, then move on.
- Adapt to project maturity (greenfield vs grayfield) rather than force a single template. Why: forcing boilerplate onto an established team creates more friction than fit.
- Require explicit confirmation before writing config or PR template. Why: these files encode a team's preferences and are easy to lose by accident.

## Asking the User

When user input is required, prefer the host's interactive question or choice tool. Fall back to plain chat otherwise. Ask one focused question at a time and wait for the answer.

In the plain-chat fallback only:
- Render multiple-choice options as standalone numbered lines (`1)`, `2)`, `3)`, ...).
- Skip Markdown ordered-list syntax (`1.`, `2.`); avoid prefixing the question itself with a number.
- Restart numbering at `1)` for every question.

## Workflow

1. Detect the repository root with `git rev-parse --show-toplevel`.
2. Check `{repo_root}/.gitkkal/config.json`.
- If the file exists, show current settings and ask for overwrite confirmation.
3. Collect settings from the user **one-by-one** in this exact order:
- `language`
- `commitPattern`
- `branchPattern`
- `splitCommits`
- `askOnAmbiguity`
- `createPrTemplate`
- Ask only one field per turn and wait for the user's answer before asking the next field.
- For each field question, include:
  - what the setting controls (plain language),
  - available options as standalone `1)`, `2)`, `3)`, ... lines,
  - recommended option with a short reason,
  - and a brief impact/tradeoff between options.
  - For boolean fields (`splitCommits`, `askOnAmbiguity`, `createPrTemplate`), show `1) true` and `2) false` as options.
- Mark recommended options with the literal suffix `(Recommended)`.
- Validate each response against allowed values. If invalid or ambiguous, re-ask the same field with allowed options.
- After all fields are collected, show a final config preview and ask for confirmation before writing.
4. Write `{repo_root}/.gitkkal/config.json` with 2-space indentation only after user confirmation.
5. If `createPrTemplate` is `true`, handle `{repo_root}/.github/PULL_REQUEST_TEMPLATE.md`.
- Detect project maturity first:
  - `greenfield`: new/minimal-history repository.
  - `grayfield`: existing project with established conventions.
- For `greenfield`, create a practical default template with `Summary`, `Changes`, `Test Plan`, and `Checklist`.
- For `grayfield`, adapt to existing project conventions:
  - inspect existing local artifacts (`.github/PULL_REQUEST_TEMPLATE*`, `CONTRIBUTING*`, docs, CI workflows, test commands),
  - if available, inspect recent PR examples (for example via GitHub CLI) to infer section naming, checklist style, and evidence expectations,
  - preserve recurring team conventions when reasonable instead of forcing generic boilerplate.
- If PR history cannot be accessed, state the limitation and fall back to local repository signals.
- Ask before overwriting when the file already exists.
- Show a short preview of proposed sections and rationale, then write only after explicit confirmation.
6. Report created/updated paths and next commands.
7. Verify: re-read `{repo_root}/.gitkkal/config.json` and confirm parsed values match the user's selections.

## Config Schema

Use this exact key set:

```json
{
  "language": "en",
  "commitPattern": "conventional",
  "branchPattern": "type/description",
  "splitCommits": true,
  "askOnAmbiguity": true,
  "createPrTemplate": false
}
```

Allowed values:
- `language`: `en` | `ko`
- `commitPattern`: `conventional` | `gitmoji` | `simple`
- `branchPattern`: `type/description` | `description-only`
- `splitCommits`: boolean
- `askOnAmbiguity`: boolean
- `createPrTemplate`: boolean

## Guardrails

- Require explicit confirmation before overwriting config or PR template. Why: these files encode a team's hard-won preferences.
- In `grayfield` projects, prioritize existing PR conventions over generic template defaults.
- Emit booleans as real JSON booleans, not strings.
- Keep the config path fixed at `.gitkkal/config.json`.
- If not in a Git repo, stop and explain the issue.
