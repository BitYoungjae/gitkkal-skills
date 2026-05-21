#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_root="$repo_root/skills"
adapters_root="$repo_root/adapters"

if [ ! -d "$skills_root" ]; then
  echo "[error] missing skills directory"
  exit 1
fi

if [ ! -d "$adapters_root" ]; then
  echo "[error] missing adapters directory"
  exit 1
fi

status=0
skill_count=0
adapter_count=0

# Extract a single frontmatter field's raw value.
# Echoes the trimmed value if present, empty otherwise.
extract_frontmatter_value() {
  local file="$1"
  local field="$2"

  awk -v field="$field" '
    BEGIN { in_fm = 0 }
    /^---$/ {
      if (in_fm == 0) { in_fm = 1; next }
      exit
    }
    in_fm == 1 {
      pattern = "^" field ":[[:space:]]*"
      if ($0 ~ pattern) {
        sub(pattern, "", $0)
        print $0
        exit
      }
    }
  ' "$file"
}

# Validate per the open Agent Skills spec (https://agentskills.io/specification).
validate_skill() {
  local skill_dir="$1"
  local skill_name
  skill_name="$(basename "$skill_dir")"
  local skill_file="$skill_dir/SKILL.md"
  local skill_ok=1

  if [ ! -f "$skill_file" ]; then
    echo "[error] $skill_name: missing SKILL.md"
    return 1
  fi

  local name desc
  name="$(extract_frontmatter_value "$skill_file" "name")"
  desc="$(extract_frontmatter_value "$skill_file" "description")"

  # name rules: required; 1-64 chars; [a-z0-9-] only;
  # must not start/end with hyphen; no consecutive hyphens; must match dir name.
  if [ -z "$name" ]; then
    echo "[error] $skill_name: missing frontmatter \`name\`"
    skill_ok=0
  else
    if [ "${#name}" -gt 64 ]; then
      echo "[error] $skill_name: \`name\` exceeds 64 chars (${#name})"
      skill_ok=0
    fi
    if ! [[ "$name" =~ ^[a-z0-9-]+$ ]]; then
      echo "[error] $skill_name: \`name\` must match ^[a-z0-9-]+$ (got: $name)"
      skill_ok=0
    fi
    if [[ "$name" == -* || "$name" == *- ]]; then
      echo "[error] $skill_name: \`name\` must not start or end with a hyphen (got: $name)"
      skill_ok=0
    fi
    if [[ "$name" == *--* ]]; then
      echo "[error] $skill_name: \`name\` must not contain consecutive hyphens (got: $name)"
      skill_ok=0
    fi
    if [ "$name" != "$skill_name" ]; then
      echo "[error] $skill_name: \`name\` field ($name) must match parent directory name ($skill_name)"
      skill_ok=0
    fi
  fi

  # description rules: required; 1-1024 chars.
  if [ -z "$desc" ]; then
    echo "[error] $skill_name: missing or empty frontmatter \`description\`"
    skill_ok=0
  else
    if [ "${#desc}" -gt 1024 ]; then
      echo "[error] $skill_name: \`description\` exceeds 1024 chars (${#desc})"
      skill_ok=0
    fi
  fi

  if [ "$skill_ok" -eq 1 ]; then
    echo "[ok] $skill_name"
    return 0
  fi
  return 1
}

while IFS= read -r skill_dir; do
  skill_count=$((skill_count + 1))
  if ! validate_skill "$skill_dir"; then
    status=1
  fi
done < <(find "$skills_root" -mindepth 1 -maxdepth 1 -type d | sort)

if [ "$skill_count" -eq 0 ]; then
  echo "[error] no skill directories found under $skills_root"
  status=1
fi

if command -v skills-ref >/dev/null 2>&1; then
  echo "[info] running skills-ref validate"
  if ! skills-ref validate "$skills_root"; then
    status=1
  fi
else
  echo "[info] skills-ref not found; skipped (install from https://github.com/agentskills/agentskills for spec-level validation)"
fi

while IFS= read -r adapter_dir; do
  adapter_name="$(basename "$adapter_dir")"
  installer="$adapter_dir/install.sh"
  valid=1
  adapter_count=$((adapter_count + 1))

  if [ ! -f "$installer" ]; then
    echo "[error] $adapter_name: missing install.sh"
    status=1
    continue
  fi

  if [ ! -x "$installer" ]; then
    echo "[error] $adapter_name: install.sh is not executable"
    status=1
    valid=0
  fi

  if ! bash -n "$installer"; then
    echo "[error] $adapter_name: install.sh has syntax errors"
    status=1
    valid=0
  fi

  if [ "$valid" -eq 1 ]; then
    echo "[ok] adapter/$adapter_name"
  fi
done < <(find "$adapters_root" -mindepth 1 -maxdepth 1 -type d | sort)

if [ "$adapter_count" -eq 0 ]; then
  echo "[error] no adapter directories found under $adapters_root"
  status=1
fi

exit "$status"
