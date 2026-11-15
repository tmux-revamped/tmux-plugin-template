#!/usr/bin/env bats

setup() {
  SOURCE_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  REPO="${BATS_TEST_TMPDIR}/$(basename "${SOURCE_ROOT}")"
  mkdir -p "${REPO}"
  tar -C "${SOURCE_ROOT}" --exclude=./.git --exclude=./coverage -cf - . | tar -C "${REPO}" --no-same-owner -xf -
  git -C "${REPO}" init --quiet --initial-branch=main
  git -C "${REPO}" config user.name "bot-checksums test"
  git -C "${REPO}" config user.email "bot-checksums@test.invalid"
  git -C "${REPO}" config commit.gpgsign false
  printf 'owned\t.github/workflows/release.yml\n' >>"${REPO}/family/OWNERSHIP"
  "${REPO}/family/bin/checksums" >/dev/null
  git -C "${REPO}" add --all
  git -C "${REPO}" commit --quiet -m "chore: start"
  START_VERSION="$(tr -d '[:space:]' <"${REPO}/family/VERSION")"
}

bot_branch_changes() {
  git -C "${REPO}" checkout --quiet -b bot main
  printf 'changed by a bot\n' >>"${REPO}/${1}"
  git -C "${REPO}" commit --quiet -am "ci: bump an action"
  BOT_SHA="$(git -C "${REPO}" rev-parse HEAD)"
  git -C "${REPO}" checkout --quiet main
}

record() {
  cd "${REPO}" || return 1
  run sh .github/scripts/bot-checksums.sh "${BOT_SHA}"
}

@test "bot-checksums - prints nothing when the bot changed no owned file" {
  # Arrange
  bot_branch_changes README.md

  # Act
  record

  # Assert
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
  [ "$(git -C "${REPO}" rev-parse --abbrev-ref HEAD)" = main ]
}

@test "bot-checksums - records the checksums and raises the contract version for an owned workflow" {
  # Arrange
  bot_branch_changes .github/workflows/release.yml

  # Act
  record

  # Assert
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(git -C "${REPO}" rev-parse HEAD)" ]
  [ "$(git -C "${REPO}" log -1 --format=%s)" = "chore(family): record the checksums of a bot update" ]
  [ "$(tr -d '[:space:]' <"${REPO}/family/VERSION")" = "$((START_VERSION + 1))" ]
  run "${REPO}/family/bin/audit"
  [ "${status}" -eq 0 ]
}

@test "bot-checksums - merges main into a bot branch that fell behind" {
  # Arrange
  bot_branch_changes .github/workflows/release.yml
  printf 'a newer main\n' >>"${REPO}/README.md"
  git -C "${REPO}" commit --quiet -am "docs: a newer main"

  # Act
  record

  # Assert
  [ "${status}" -eq 0 ]
  git -C "${REPO}" merge-base --is-ancestor main HEAD
  git -C "${REPO}" merge-base --is-ancestor "${BOT_SHA}" HEAD
  run "${REPO}/family/bin/audit"
  [ "${status}" -eq 0 ]
}

@test "bot-checksums - refuses a bot change to an owned file bots never edit" {
  # Arrange
  bot_branch_changes src/lib/utils/cache.sh

  # Act
  record

  # Assert
  [ "${status}" -eq 1 ]
  [ "${output}" = "::error::src/lib/utils/cache.sh: a bot changed an owned file that bots never edit" ]
  [ "$(git -C "${REPO}" rev-parse --abbrev-ref HEAD)" = main ]
}

@test "bot-checksums - refuses a bot branch that conflicts with main" {
  # Arrange
  bot_branch_changes .github/workflows/release.yml
  printf 'main changed it too\n' >>"${REPO}/.github/workflows/release.yml"
  git -C "${REPO}" commit --quiet -am "ci: change the workflow on main"

  # Act
  record

  # Assert
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"::error::the bot branch does not merge cleanly with "* ]]
}

@test "bot-checksums - prints the usage without a head sha" {
  # Arrange
  cd "${REPO}" || return 1

  # Act
  run sh .github/scripts/bot-checksums.sh

  # Assert
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"usage: sh .github/scripts/bot-checksums.sh <bot-head-sha>"* ]]
}

@test "bot-checksums - refuses a bot branch that edits the recorded checksums" {
  # Arrange
  bot_branch_changes .github/workflows/release.yml
  git -C "${REPO}" checkout --quiet bot
  printf 'forged\n' >>"${REPO}/family/CHECKSUMS"
  git -C "${REPO}" commit --quiet -am "ci: forge the checksums"
  BOT_SHA="$(git -C "${REPO}" rev-parse HEAD)"
  git -C "${REPO}" checkout --quiet main

  # Act
  record

  # Assert
  [ "${status}" -eq 1 ]
  [ "${output}" = "::error::the bot branch changes the family tooling" ]
}
