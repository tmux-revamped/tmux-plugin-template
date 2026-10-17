#!/usr/bin/env bats

@test "docs - every relative README link points at an existing path" {
  # Arrange
  local repo="${BATS_TEST_DIRNAME}/.."
  local target missing=""

  # Act
  while IFS= read -r target; do
    case "${target}" in
      http://* | https://* | mailto:* | '#'*) continue ;;
    esac
    [[ -e "${repo}/${target%%#*}" ]] || missing="${missing} ${target}"
  done < <(grep -oE '\]\([^)]+\)' "${repo}/README.md" | sed -E 's/^\]\(//; s/\)$//')

  # Assert
  [[ -z "${missing}" ]]
}
