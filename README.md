# gitkkal-skills

> The name comes from the Korean expression "gikkal-nada", meaning "stylish" or "impressive."

[한국어](./README.ko.md)

Agent-agnostic Git workflow skills for branch naming, commit generation, and pull request authoring.

## Included Skills

- `gitkkal-init`: Configure `.gitkkal/config.json` and optional PR template
- `gitkkal-branch`: Create semantic branch names from code changes or a hint
- `gitkkal-commit`: Create semantic commits in configured message style
- `gitkkal-pr`: Create or update PRs from branch intent and recent changes

## Quick Start

Depending on your agent host, use slash command style, `$skill` style, or plain language.

```text
gitkkal-init
gitkkal-branch [description]
gitkkal-commit [hint]
gitkkal-pr [hint]
```

Examples:

```text
gitkkal-init
gitkkal-branch add user authentication
gitkkal-commit emphasize validation and tests
gitkkal-pr focus on retry logic and error handling
```

## Typical Workflow

1. Create a branch:
   - `gitkkal-branch add user authentication`
2. Commit your changes:
   - `gitkkal-commit`
3. Create a pull request:
   - `gitkkal-pr`
4. Update the same PR after more commits:
   - `gitkkal-pr emphasize refactoring scope`

## Hint-First Behavior

- `gitkkal-branch`, `gitkkal-commit`, and `gitkkal-pr` accept one optional free-form hint.
- Hints are advisory, not strict parameters.
- If no hint is provided, skills infer intent from git diff/history.
- If hint conflicts with observed changes, skills ask for clarification.

## Configuration

`gitkkal-init` creates `.gitkkal/config.json`:

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

| Option             | Values                                     | Description                               |
| ------------------ | ------------------------------------------ | ----------------------------------------- |
| `language`         | `"en"`, `"ko"`                             | Output language preference                |
| `commitPattern`    | `"conventional"`, `"gitmoji"`, `"simple"`  | Commit message format                     |
| `branchPattern`    | `"type/description"`, `"description-only"` | Branch naming format                      |
| `splitCommits`     | `true`, `false`                            | Split changes by semantic unit            |
| `askOnAmbiguity`   | `true`, `false`                            | Ask user if intent is unclear             |
| `createPrTemplate` | `true`, `false`                            | Create `.github/PULL_REQUEST_TEMPLATE.md` |

If config is missing, default values are used.

## PR Template Generation

When `createPrTemplate=true`, `gitkkal-init` detects project maturity:

- `greenfield`: creates a practical default template (`Summary`, `Changes`, `Test Plan`, `Checklist`)
- `grayfield`: adapts to existing project conventions by checking local docs/workflows and, when available, recent PR examples

- `greenfield` means a new or lightly governed project with no strong existing PR convention.
- `grayfield` means an established project that already has its own PR or development workflow conventions.

Existing template files are never overwritten without explicit confirmation.

## Install (Codex)

Install all skills:

```bash
bash adapters/codex/install.sh
```

Install selected skills:

```bash
bash adapters/codex/install.sh gitkkal-init gitkkal-commit
```

## Install (Claude)

User scope (`~/.claude/skills`):

```bash
bash adapters/claude/install.sh --scope user
```

Project scope (`<project>/.claude/skills`):

```bash
bash adapters/claude/install.sh --scope project --project-root /path/to/project
```

## Requirements

- Git repository
- `gh` (GitHub CLI) for PR create/update actions

If `gh` is unavailable, `gitkkal-pr` falls back to generating PR title/body text and executable commands.

## Repository Structure

```text
skills/                 # Portable skill definitions
adapters/codex/         # Install helper for Codex
adapters/claude/        # Install helper for Claude
scripts/                # Validation and packaging helpers
.github/workflows/      # Release automation
```

## Validate

```bash
bash scripts/validate.sh
```

## Release

Create tag locally (after first commit exists):

```bash
bash scripts/create-release-tag.sh v1.0.0
```

Push tag when ready:

```bash
git push origin v1.0.0
```

GitHub Actions packages each skill as `tar.gz` and attaches artifacts to the release.
