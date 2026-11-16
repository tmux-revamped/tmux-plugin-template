#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031,SC2034

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  ROOT="$(cd "${REVAMPED_TESTS_DIR}/.." && pwd)"
}

scaffold() {
  sh "${ROOT}/.github/scripts/new-member.sh" "$@"
}

@test "new-member - scaffolds a member whose tool answers under the new name" {
  # Arrange
  local dest="${BATS_TEST_TMPDIR}/tmux git-status-revamped"
  scaffold git-status "${dest}"

  # Act
  run "${dest}/bin/git-status-revamped" version

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "git-status-revamped 0.0.0" ]]
  [[ -f "${dest}/man/git-status-revamped.1" ]]
  [[ -f "${dest}/completions/_git-status-revamped" ]]
  grep -qx 'readonly GIT_STATUS_REVAMPED_VERSION="0.0.0"' "${dest}/lib/core.sh"
}

@test "new-member - leaves no template name in the code it copies" {
  # Arrange
  local dest="${BATS_TEST_TMPDIR}/tmux-clipboard-revamped"
  scaffold clipboard "${dest}"

  # Act
  run grep -rlE 'template[-_]revamped|TEMPLATE[-_]REVAMPED|TMUX_PLUGIN_TEMPLATE|tmux-plugin-template' \
    "${dest}/bin" "${dest}/lib" "${dest}/man" "${dest}/completions" "${dest}/screens" "${dest}/Makefile"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ -z "${output}" ]]
}

@test "new-member - keeps the family files byte for byte" {
  # Arrange
  local dest="${BATS_TEST_TMPDIR}/tmux-clipboard-revamped"

  # Act
  scaffold clipboard "${dest}"

  # Assert
  cmp "${ROOT}/FAMILY.md" "${dest}/FAMILY.md"
  cmp "${ROOT}/.github/scripts/set-version.sh" "${dest}/.github/scripts/set-version.sh"
  cmp "${ROOT}/lib/ui.sh" "${dest}/lib/ui.sh"
}

@test "new-member - leaves out the template's own README, changelog, recordings and scaffold" {
  # Arrange
  local dest="${BATS_TEST_TMPDIR}/tmux-clipboard-revamped"

  # Act
  scaffold clipboard "${dest}"

  # Assert
  [[ ! -e "${dest}/CHANGELOG.md" ]]
  [[ ! -e "${dest}/README.ja.md" ]]
  [[ ! -e "${dest}/screens/hero.gif" ]]
  [[ ! -e "${dest}/.github/scripts/new-member.sh" ]]
  run grep -c 'new-member' "${dest}/Makefile"
  [[ "${output}" == "0" ]]
  grep -q '^\.PHONY: help fmt lint test test-all test-linux coverage check screens install clean$' "${dest}/Makefile"
  grep -q '^<!-- family:begin -->$' "${dest}/README.md"
  grep -q '^## Gaps against FAMILY.md$' "${dest}/AGENTS.md"
}

@test "new-member - stages every file in a new repository" {
  # Arrange
  local dest="${BATS_TEST_TMPDIR}/tmux-clipboard-revamped"

  # Act
  scaffold clipboard "${dest}"

  # Assert
  run git -C "${dest}" status --porcelain
  [[ "${output}" != *"??"* ]]
  [[ "${output}" == *"A  bin/clipboard-revamped"* ]]
}

@test "new-member - refuses a missing name" {
  # Arrange
  local dest="${BATS_TEST_TMPDIR}/tmux--revamped"

  # Act
  run scaffold "" "${dest}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "new-member: give the plugin a name: make new-member NAME=example" ]]
  [[ ! -e "${dest}" ]]
}

@test "new-member - refuses a name that is not lowercase words joined by hyphens" {
  # Arrange
  local name=Git_Status

  # Act
  run scaffold "${name}" "${BATS_TEST_TMPDIR}/dest"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "new-member: a name is lowercase letters, digits and single hyphens, such as clipboard or git-status, got: Git_Status" ]]
}

@test "new-member - refuses the template's own name" {
  # Arrange
  local name=template

  # Act
  run scaffold "${name}" "${BATS_TEST_TMPDIR}/dest"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "new-member: template is the name of this repository" ]]
}

@test "new-member - refuses a missing destination" {
  # Arrange
  local name=clipboard

  # Act
  run scaffold "${name}" ""

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "new-member: give the destination: make new-member NAME=example DEST=../tmux-example-revamped" ]]
}

@test "new-member - refuses a destination that exists" {
  # Arrange
  local dest="${BATS_TEST_TMPDIR}/taken"
  mkdir -p "${dest}"

  # Act
  run scaffold clipboard "${dest}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "new-member: ${dest} already exists" ]]
}

@test "new-member - refuses a template that is not a git checkout" {
  # Arrange
  local copy="${BATS_TEST_TMPDIR}/copy"
  mkdir -p "${copy}/.github/scripts"
  cp -p "${ROOT}/.github/scripts/new-member.sh" "${copy}/.github/scripts/"

  # Act
  run sh "${copy}/.github/scripts/new-member.sh" clipboard "${BATS_TEST_TMPDIR}/dest"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "new-member: ${copy} is not a git checkout, so there is no list of files to copy" ]]
  [[ ! -e "${BATS_TEST_TMPDIR}/dest" ]]
}
