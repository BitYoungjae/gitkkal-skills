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

check_frontmatter() {
  local file="$1"
  local field="$2"

  if awk -v field="$field" '
    BEGIN { in_frontmatter = 0; found = 0 }
    /^---$/ {
      if (in_frontmatter == 0) {
        in_frontmatter = 1
        next
      }
      exit
    }
    in_frontmatter == 1 && $0 ~ ("^" field ":[[:space:]]*[^[:space:]]") { found = 1; exit }
    END { exit(found ? 0 : 1) }
  ' "$file"; then
    return 0
  fi

  return 1
}

while IFS= read -r skill_dir; do
  skill_name="$(basename "$skill_dir")"
  skill_file="$skill_dir/SKILL.md"
  skill_ok=1
  skill_count=$((skill_count + 1))

  if [ ! -f "$skill_file" ]; then
    echo "[error] $skill_name: missing SKILL.md"
    status=1
    skill_ok=0
    continue
  fi

  if ! check_frontmatter "$skill_file" "name"; then
    echo "[error] $skill_name: missing frontmatter name"
    status=1
    skill_ok=0
  fi

  if ! check_frontmatter "$skill_file" "description"; then
    echo "[error] $skill_name: missing frontmatter description"
    status=1
    skill_ok=0
  fi

  if [ "$skill_ok" -eq 1 ]; then
    echo "[ok] $skill_name"
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
  echo "[info] skills-ref not found; skipped"
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
