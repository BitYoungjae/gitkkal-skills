#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_root="$repo_root/skills"
dist_dir="$repo_root/dist"
cd "$repo_root"

usage() {
  cat <<USAGE
Usage: bash scripts/package.sh [--skill SKILL ...] [--output-dir PATH]

Examples:
  bash scripts/package.sh
  bash scripts/package.sh --skill gitkkal-init
  bash scripts/package.sh --output-dir /tmp/dist-packages
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
    error "missing skills directory: $skills_root"
    exit 1
  fi

while IFS= read -r skill_dir; do
  [ -z "$skill_dir" ] && continue
  printf '%s\n' "${skill_dir##*/}"
done < <(find "$skills_root" -mindepth 1 -maxdepth 1 -type d | sort)
}

selected_skills=()
args=()

while (($#)); do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --output-dir)
      require_value "$1" "${2:-}"
      dist_dir="$2"
      shift 2
      ;;
    --skill)
      require_value "$1" "${2:-}"
      selected_skills+=("$2")
      shift 2
      ;;
    --)
      shift
      while (($#)); do
        args+=("$1")
        shift
      done
      ;;
    -*)
      error "unknown option: $1"
      usage
      exit 1
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

if [ ${#args[@]} -gt 0 ]; then
  for explicit_skill in "${args[@]}"; do
    selected_skills+=("$explicit_skill")
  done
fi

if [ ! -d "$skills_root" ]; then
  error "missing skills directory: $skills_root"
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  error "tar is required"
  exit 1
fi

mkdir -p "$dist_dir"
rm -f "$dist_dir"/*.tar.gz

if [ "${#selected_skills[@]}" -eq 0 ]; then
  while IFS= read -r skill_name; do
    selected_skills+=("$skill_name")
  done < <(discover_skills)
fi

if [ "${#selected_skills[@]}" -eq 0 ]; then
  error "no skill directories found under $skills_root"
  exit 1
fi

packaged_count=0
for skill_name in "${selected_skills[@]}"; do
  skill_dir="$skills_root/$skill_name"
  if [ ! -d "$skill_dir" ]; then
    echo "[warn] skill not found: $skill_name"
    continue
  fi

  tar -czf "$dist_dir/${skill_name}.tar.gz" -C "$skills_root" "$skill_name"
  echo "[ok] packaged: ${dist_dir}/${skill_name}.tar.gz"
  packaged_count=$((packaged_count + 1))
done

if [ "$packaged_count" -eq 0 ]; then
  error "no valid skills were packaged (check requested skill names)"
  exit 1
fi

echo "[ok] packaged_count=$packaged_count"
