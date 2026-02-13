#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: bash scripts/create-release-tag.sh [TAG]

Examples:
  bash scripts/create-release-tag.sh v1.0.0
  bash scripts/create-release-tag.sh
USAGE
}

if [ $# -eq 0 ]; then
  tag="v1.0.0"
elif [ $# -eq 1 ]; then
  tag="$1"
  if [ "$tag" = "-h" ] || [ "$tag" = "--help" ]; then
    usage
    exit 0
  fi
else
  echo "[error] too many arguments"
  usage
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[error] not a git repository"
  exit 1
fi

if ! git check-ref-format "refs/tags/$tag" >/dev/null 2>&1; then
  echo "[error] invalid tag name: $tag"
  exit 1
fi

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "[error] cannot create tag '$tag' because HEAD does not exist yet"
  echo "[hint] create at least one commit first, then run: bash scripts/create-release-tag.sh $tag"
  exit 1
fi

if git show-ref --tags --verify --quiet "refs/tags/$tag"; then
  echo "[error] tag already exists: $tag"
  exit 1
fi

git tag "$tag"
echo "[ok] created tag: $tag"
