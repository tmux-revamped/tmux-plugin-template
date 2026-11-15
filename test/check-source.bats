#!/usr/bin/env bats

setup() {
  SOURCE_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  REPO="${BATS_TEST_TMPDIR}/$(basename "${SOURCE_ROOT}")"
  mkdir -p "${REPO}"
  tar -C "${SOURCE_ROOT}" --exclude=./.git --exclude=./coverage -cf - . | tar -C "${REPO}" --no-same-owner -xf -
  git -C "${REPO}" init --quiet
  git -C "${REPO}" add --all
}

write_source() {
  printf '%s\n' "${@:2}" >"${REPO}/src/lib/utils/${1}"
  git -C "${REPO}" add --all
}

check() {
  run sh "${REPO}/scripts/check-source.sh"
}

@test "check-source - passes the template as it is" {
  # Arrange
  local script="${REPO}/scripts/check-source.sh"

  # Act
  run sh "${script}"

  # Assert
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

@test "check-source - reports a source file without the bash shebang" {
  # Arrange
  write_source probe.sh '#!/bin/sh' 'true'

  # Act
  check

  # Assert
  [ "${status}" -eq 1 ]
  [ "${output}" = "src/lib/utils/probe.sh: the first line is not #!/usr/bin/env bash" ]
}

@test "check-source - reports a source guard the test helpers never unset" {
  # Arrange
  write_source probe.sh '#!/usr/bin/env bash' '_TMUX_PLUGIN_PROBE_LOADED=1'

  # Act
  check

  # Assert
  [ "${status}" -eq 1 ]
  [ "${output}" = "_TMUX_PLUGIN_PROBE_LOADED: a source guard the test helpers never unset" ]
}

@test "check-source - reports a source file past 500 lines" {
  # Arrange
  write_source probe.sh '#!/usr/bin/env bash' $(seq 1 500)

  # Act
  check

  # Assert
  [ "${status}" -eq 1 ]
  [ "${output}" = "src/lib/utils/probe.sh: 501 lines, more than 500" ]
}

@test "check-source - accepts a long source file the allowlist names" {
  # Arrange
  write_source probe.sh '#!/usr/bin/env bash' $(seq 1 500)
  printf 'src/lib/utils/probe.sh 600\n' >"${REPO}/.github/file-size-allowlist"

  # Act
  check

  # Assert
  [ "${status}" -eq 0 ]
}

@test "check-source - reports an option the README never names" {
  # Arrange
  write_source probe.sh '#!/usr/bin/env bash' 'tmux show -gqv @plugin-template_revamped_probe'

  # Act
  check

  # Assert
  [ "${status}" -eq 1 ]
  [ "${output}" = "@plugin-template_revamped_probe: not documented in README.md" ]
}

@test "check-source - reports a version constant that differs from the changelog" {
  # Arrange
  sed 's/^readonly TMUX_PLUGIN_TEMPLATE_VERSION=.*/readonly TMUX_PLUGIN_TEMPLATE_VERSION="9.9.9"/' \
    "${SOURCE_ROOT}/src/lib/utils/constants.sh" >"${REPO}/src/lib/utils/constants.sh"

  # Act
  check

  # Assert
  [ "${status}" -eq 1 ]
  [[ "${output}" == "the version constant 9.9.9 differs from the newest CHANGELOG.md release "* ]]
}

@test "check-source - reads a minor release heading written at level one" {
  # Arrange
  sed 's/^readonly TMUX_PLUGIN_TEMPLATE_VERSION=.*/readonly TMUX_PLUGIN_TEMPLATE_VERSION="1.1.0"/' \
    "${SOURCE_ROOT}/src/lib/utils/constants.sh" >"${REPO}/src/lib/utils/constants.sh"
  printf '# Changelog\n\n# [1.1.0](https://example.invalid) (2026-11-15)\n\n## [1.0.0] - 2026-06-19\n' >"${REPO}/CHANGELOG.md"

  # Act
  check

  # Assert
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}
