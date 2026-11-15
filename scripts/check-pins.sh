#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
cd "${root}"

# shellcheck disable=SC2016
refs=$(git ls-files -z -- '.github/workflows/*.yml' | xargs -0 awk '
  /^[[:space:]]*-?[[:space:]]*uses:/ {
    ref = $0
    sub(/^[^:]*uses:[[:space:]]*/, "", ref)
    sub(/[[:space:]].*$/, "", ref)
    print FILENAME ":" FNR ": " ref
  }')

unpinned=$(printf '%s\n' "${refs}" | awk -F': ' '
  NF < 2 { next }
  $2 ~ /^\.\// { next }
  $2 ~ /^docker:\/\/.*@sha256:[0-9a-f]{64}$/ { next }
  $2 ~ /^[^@]+@[0-9a-f]{40}$/ { next }
  { print }')

if [ -n "${unpinned}" ]; then
  printf 'an action or image not pinned to a full commit SHA or image digest:\n%s\n' "${unpinned}" >&2
  exit 1
fi
