---
name: gitkkal-init
description: Configure gitkkal for the current repository by creating or updating `.gitkkal/config.json` and optional PR template files. Use when the user asks to run `/gitkkal:init` or `$gitkkal-init`, set commit/branch style preferences, switch message language, or bootstrap gitkkal in a new repo.
---

# Gitkkal Init

Configure gitkkal settings interactively for the current Git repository.

## Agent-Agnostic Rules

- Do not assume client-specific UI features (forms, plan mode, special slash-command runtime).
- Treat trigger command examples as optional; plain-language requests are equally valid.
- Collect required input in plain chat prompts.
- Ask one clear question at a time when user input is needed.
- If presenting a multiple-choice question, use numbered options (`1)`, `2)`, `3)`, ...) so users can reply by number.
  - Always print each option as standalone `1)`, `2)`, ... lines.
  - Restart numbering at `1)` for every question.
  - Do not use Markdown ordered-list syntax (`1.`, `2.`, ...), and do not prefix question text with list numbers.

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

- Never overwrite config or PR template without explicit confirmation.
- In `grayfield` projects, prioritize existing PR conventions over generic template defaults.
- Keep booleans as real JSON booleans.
- Keep the config path fixed at `.gitkkal/config.json`.
- If not in a Git repo, stop and explain the issue.
