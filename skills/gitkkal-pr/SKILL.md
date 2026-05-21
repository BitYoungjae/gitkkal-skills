---
name: gitkkal-pr
description: Create or update GitHub pull requests from the current branch using audience-friendly summaries and test plans. Use when the user asks for `/gitkkal:pr` or `$gitkkal-pr`, optionally provides a free-form hint, wants automated PR title/body generation, or wants existing PR content rewritten after new commits.
---

# Gitkkal PR

Create or refresh a pull request using current branch history and intent.

The PR body must be readable by **non-developers** (product managers, designers, support engineers, business stakeholders). Anyone should be able to grasp the purpose and impact of the change without opening the diff.

## Operating Principles

- Accept one optional free-form hint (e.g., command tail text); treat as advisory framing, not a hard constraint.
- Plain-language requests are equivalent to slash-command triggers.
- Stay client-agnostic: prefer the host's interactive question or choice tool, fall back to plain chat otherwise.

## Persona

- Outcome-led: lead title and body with what changes for users or the team, not which files moved.
- Escalate investigation in stages (commits → file-level diffs → ask the user). Why: most PRs reveal their purpose in the commit log; deeper reads cost tokens.
- Cite the diff for impact claims; never invent file or function names.

## Asking the User

When user input is required (ambiguous intent, clarifying base branch or PR focus, choosing between options), prefer the host's interactive question or choice tool. Fall back to plain chat otherwise. Ask one focused question at a time and wait for the answer.

In the plain-chat fallback only:
- Render multiple-choice options as standalone numbered lines (`1)`, `2)`, `3)`, ...).
- Skip Markdown ordered-list syntax (`1.`, `2.`); avoid prefixing the question itself with a number.
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
6. Analyze branch intent using staged escalation; stop as soon as purpose is clear.
   - Step 1: Read commit messages and `git diff --stat` from base to `HEAD`. If purpose is clear, proceed.
   - Step 2: Otherwise, read targeted file-level diffs only for the files whose intent is ambiguous.
   - Step 3: If purpose is still unclear after reading diffs, ask the user for the PR's primary focus before writing. Do not guess.
   - Focus on purpose and impact rather than listing files.
   - Classify the change into one of three categories before writing (see Change Categories below).
7. Build PR content.
   - Keep title under 50 chars, imperative mood, lead with the outcome (not the implementation).
   - Follow configured language (`en` or `ko`) when available.
   - Body must include `Background`, `What Changes`, and `Test Plan` sections. Add `Technical Notes` only when there is meaningful implementation detail for reviewers.
   - If repository PR template exists, follow that structure but still apply the Audience Principle and refactor framings inside whatever sections the template provides.
8. Execute action.
   - In normal mode:
     - Creation: push branch if needed, then `gh pr create --title ... --body ...`.
     - Update: fully replace existing title/body with `gh pr edit`.
   - In fallback mode:
     - return final title/body text and command snippets only.
9. Report resulting PR number, URL, and mode (created or updated).

## Change Categories

Before writing the body, classify the PR. Each category gets a different framing.

| Category | What the PR does | Audience framing |
|----------|------------------|------------------|
| User-facing | Adds/changes/fixes something users or external clients see or experience | "What can users now do, or no longer suffer from?" |
| Internal capability | Adds a building block other features will use (new API, infra, library) | "What does this unlock for the team or product?" |
| Pure refactor / maintenance | No behavior change — restructures, renames, cleans up | "What development pain does this remove?" |

## PR Body Structure

```markdown
## Background
<1-3 sentences explaining the problem, motivation, or context behind this PR>

## What Changes
- <Concrete user-visible or product-visible change>
- <Another change, grouped conceptually>

## Technical Notes
<Optional. Implementation details for reviewers: architecture choices, library/API picks, migration notes, follow-ups. Omit the section entirely when there is nothing meaningful to say here.>

## Test Plan
- [ ] <Test item 1>
- [ ] <Test item 2>
```

### The Audience Principle

The reader of `Background` and `What Changes` is **someone who does not read the diff**. Write so they can:

1. Understand **why this PR exists** without prior context.
2. Picture **what changes for users or the product** after merge.
3. Skip `Technical Notes` and still grasp the full point of the PR.

Concrete rules for `Background` + `What Changes`:

- **Lead with the problem or user outcome**, not the file or function. Function and module names belong in `Technical Notes` or the diff.
- **Use plain product or business vocabulary** ("checkout page", "signup form", "support ticket volume"). Translate jargon when first introduced. "JWT token" → "the login token we issue users".
- **Quantify impact when possible** ("removes ~30% of failed signup attempts", "responses now arrive within 200ms").
- **One bullet = one observable change**. Group related code edits into a single bullet about the *effect*.

### Verbosity Targets

- `Background`: 1–3 sentences.
- `What Changes`: 2–6 bullets, each one observable change.
- `Technical Notes`: 0–6 bullets or 1 short paragraph. Omit the section if nothing meaningful.
- `Test Plan`: 2–6 checklist items.

## Title Examples

Good titles lead with the outcome the user or team experiences:

| Commits / changes | Category | Title |
|-------------------|----------|-------|
| 3 commits adding validation + tests | User-facing | "Block invalid submissions before they reach support" |
| Bug fix + null checks + error logging | User-facing | "Fix crash when users enter unusual input" |
| New `BillingClient` module, no UI yet | Internal capability | "Add billing client so checkout can charge cards" |
| Rename `SKU` to `BundleID` across 10 files | Pure refactor | "Rename SKU to BundleID to match product terminology" |
| Extract 4 helper modules from one 800-line file | Pure refactor | "Split order module to make future changes safer" |

Bad title: "Various updates" — too vague, lists changes without purpose.

## Body Examples

### Good — user-facing PR

```markdown
## Background
Users keep mistyping their email on signup (e.g. `name@gmial.com`), get a generic "signup failed" message, and bounce. Support has handled ~40 tickets/month about this.

## What Changes
- The signup form now catches common email typos before submission and suggests a correction inline.
- Failed submissions show a specific message ("Did you mean `name@gmail.com`?") instead of a generic error.
- Already-supported flows (Google/Apple sign-in) are untouched.

## Technical Notes
- Validation runs client-side via the new `suggestEmailFix()` helper; no new server calls.
- `validateEmail` is reused by the API layer for defense-in-depth.

## Test Plan
- [ ] Mistype a common gmail typo and confirm the inline suggestion appears.
- [ ] Submit a valid email and confirm signup still succeeds.
- [ ] Confirm Google/Apple sign-in flows are unchanged.
```

### Bad — describes files instead of impact

```markdown
## Summary
- Modified user.js
- Added validateEmail function
- Updated tests for user.test.js
- Refactored form submission handler

## Test plan
- [ ] Run tests
```

### Good — pure refactor PR

When there is no user-visible change, never write "no user impact" or leave `Background` empty. Translate the work into **developer productivity, reliability, or future-capability value**.

| Engineering reality | Audience-friendly framing |
|---------------------|---------------------------|
| Split 1 file into 4 modules | "Future changes to this area are smaller and safer to review" |
| Add typed interfaces | "Catches a class of bugs at build time instead of in production" |
| Rename `SKU` → `BundleID` | "Code now uses the same word ('bundle') we use in product and docs, reducing onboarding confusion" |
| Remove dead code | "Removes ~800 lines that no longer ran, shrinking the area future bugs can hide in" |
| Replace custom impl with library X | "Hands maintenance to a well-supported library; lets the team focus on product work" |

```markdown
## Background
The order module has grown to 800 lines and mixes pricing, inventory, and fulfillment logic. Adding even small features here keeps touching unrelated code, which slows reviews and creates merge conflicts across teams.

## What Changes
- Splits the order module into three focused modules (pricing, inventory, fulfillment).
- No behavior change for users or APIs — same inputs produce the same outputs.
- Future order-related features can be reviewed by the relevant team alone.

## Technical Notes
- Public exports unchanged; only internal structure moved.
- Each new module owns its tests; existing tests pass without modification.

## Test Plan
- [ ] Existing order test suite passes without modification.
- [ ] Spot-check a recent order-related bug repro still behaves identically.
```

## Guardrails

- Skip `Co-Authored-By` lines in PR body.
- Never modify merged PRs.
- In update mode, rewrite the description completely rather than appending to stale content.
- If intent is ambiguous, ask the user for the PR's primary focus.
- For refactor PRs, translate work into developer-productivity or reliability value instead of writing "no user impact".
