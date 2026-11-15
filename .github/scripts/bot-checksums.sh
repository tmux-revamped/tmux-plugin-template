#!/bin/sh
set -eu

head_sha="${1:?usage: sh .github/scripts/bot-checksums.sh <bot-head-sha>}"
root=$(git rev-parse --show-toplevel)
cd "${root}"
base=$(git rev-parse HEAD)

fail() {
  printf '::error::%s\n' "$1" >&2
  exit 1
}

owned_changes() {
  git diff --name-only "${base}...${head_sha}" | awk 'NR == FNR { owned[$2] = 1; next } owned[$0]' family/CHECKSUMS -
}

changed=$(owned_changes)
[ -n "${changed}" ] || exit 0

printf '%s\n' "${changed}" | while IFS= read -r path; do
  bash -c '. family/lib/common.sh && family_bot_editable "$1"' bot_editable "${path}" || fail "${path}: a bot changed an owned file that bots never edit"
done

git checkout -q -B bot-checksums "${head_sha}"
git merge -q --no-edit "${base}" || fail "the bot branch does not merge cleanly with ${base}"
git diff --quiet "${base}" HEAD -- family || fail "the bot branch changes the family tooling"

version=$(tr -d '[:space:]' <family/VERSION)
printf '%s\n' "$((version + 1))" >family/VERSION
family/bin/checksums >/dev/null
git add family/VERSION family/CHECKSUMS
git commit -q -m "chore(family): record the checksums of a bot update"
git rev-parse HEAD
