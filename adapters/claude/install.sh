#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
skills_root="$repo_root/skills"
scope="user"
project_root=""
dest=""
force=0

usage() {
  cat <<USAGE
Usage: bash adapters/claude/install.sh [--scope user|project] [--project-root PATH] [--dest PATH] [--force] [skill...]

Examples:
  bash adapters/claude/install.sh --scope user
  bash adapters/claude/install.sh --scope project --project-root /path/to/project
  bash adapters/claude/install.sh --dest /tmp/claude-skills gitkkal-init
  bash adapters/claude/install.sh --scope project --project-root /path/to/project -- gitkkal-pr
USAGE
}

error() {
  echo "[error] $*" >&2
}

require_value() {
  local flag="$1"
  if [ "${2:-}" = "" ]; then
    error "$flag requires a value"
    usage
    exit 1
  fi
}

discover_skills() {
  if [ ! -d "$skills_root" ]; then
    error "skills directory not found: $skills_root"
    exit 1
  fi

  while IFS= read -r skill_dir; do
    [ -z "$skill_dir" ] && continue
    echo "$(basename "$skill_dir")"
  done < <(find "$skills_root" -mindepth 1 -maxdepth 1 -type d | sort)
}

args=()
while (($#)); do
  case "$1" in
    --scope)
      require_value "$1" "${2:-}"
      scope="$2"
      shift 2 ;;
    --project-root)
      require_value "$1" "${2:-}"
      project_root="$2"
      shift 2 ;;
    --dest)
      require_value "$1" "${2:-}"
      dest="$2"
      shift 2 ;;
    --force)
      force=1; shift ;;
    --)
      shift
      while (($#)); do
        args+=("$1")
        shift
      done
      ;;
    -h|--help)
      usage; exit 0 ;;
    -*)
      error "unknown option: $1"
      usage
      exit 1 ;;
    *)
      args+=("$1"); shift ;;
  esac
done

if [ -z "$dest" ]; then
  case "$scope" in
    user)
      dest="$HOME/.claude/skills" ;;
    project)
      if [ -z "$project_root" ]; then
        echo "[error] --project-root is required when --scope project"
        exit 1
      fi
      if [ ! -d "$project_root" ]; then
        echo "[error] project root not found: $project_root"
        exit 1
      fi
      dest="$project_root/.claude/skills" ;;
    *)
      echo "[error] invalid scope: $scope"
      exit 1 ;;
  esac
fi

if [ ${#args[@]} -eq 0 ]; then
  while IFS= read -r skill_name; do
    args+=("$skill_name")
  done < <(discover_skills)
fi

if [ ${#args[@]} -eq 0 ]; then
  error "no skills found under $skills_root"
  exit 1
fi

mkdir -p "$dest"
installed=()
skipped=()

for skill in "${args[@]}"; do
  src="$skills_root/$skill"
  dst="$dest/$skill"
  if [ ! -d "$src" ]; then
    echo "[warn] skill not found: $skill"
    continue
  fi

  if [ -e "$dst" ] && [ "$force" -ne 1 ]; then
    skipped+=("$skill")
    echo "[skip] exists: $dst (use --force to overwrite)"
    continue
  fi

  rm -rf "$dst"
  cp -R "$src" "$dst"
  installed+=("$skill")
  echo "[ok] installed: $skill -> $dst"
done

echo ""
echo "Installed: ${#installed[@]}"
echo "Skipped: ${#skipped[@]}"
