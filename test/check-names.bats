#!/usr/bin/env bats

setup() {
  SOURCE_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  REPO="${BATS_TEST_TMPDIR}/$(basename "${SOURCE_ROOT}")"
  mkdir -p "${REPO}"
  tar -C "${SOURCE_ROOT}" --exclude=./.git --exclude=./coverage -cf - . | tar -C "${REPO}" --no-same-owner -xf -
  git -C "${REPO}" init --quiet
  git -C "${REPO}" add --all
}

plant() {
  printf '%s\n' "${2}" >"${REPO}/${1}"
  git -C "${REPO}" add --all
}

check() {
  run sh "${REPO}/scripts/check-names.sh"
}

@test "check-names - passes the template as it is" {
  # Arrange
  local script="${REPO}/scripts/check-names.sh"

  # Act
  run sh "${script}"

  # Assert
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

@test "check-names - reports a dd read that keeps NUL bytes" {
  # Arrange
  plant src/probe.sh 'bytes=$(dd if=f bs=1 count=4)'

  # Act
  check

  # Assert
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"src/probe.sh:1: a dd read into a variable keeps its NUL bytes"* ]]
}

@test "check-names - reports a brace group that closes on a redirect" {
  # Arrange
  plant src/probe.sh '} >out'

  # Act
  check

  # Assert
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"src/probe.sh:1: a brace group closes on a redirect bashcov cannot count"* ]]
}

@test "check-names - reports a loop that redirects a fixed descriptor" {
  # Arrange
  plant src/probe.sh 'done 3<list'

  # Act
  check

  # Assert
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"src/probe.sh:1: a loop redirects a fixed descriptor bashcov can take"* ]]
}

@test "check-names - reports an awk function named like a gawk built-in" {
  # Arrange
  plant src/probe.sh 'function xor(a, b) { return a }'

  # Act
  check

  # Assert
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"src/probe.sh:1: an awk function is named like a gawk built-in"* ]]
}

@test "check-names - reports a mkdir lock" {
  # Arrange
  plant src/probe.sh 'while ! mkdir "${lock}"; do sleep 1; done'

  # Act
  check

  # Assert
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"src/probe.sh:1: a lock is taken with mkdir"* ]]
}

@test "check-names - reports a size read with wc" {
  # Arrange
  plant src/probe.sh 'size=$(wc -c <"${file}")'

  # Act
  check

  # Assert
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"src/probe.sh:1: a file size is read with wc, which BusyBox counts in 32 bits"* ]]
}

@test "check-names - reports a backup name that drops the extension" {
  # Arrange
  plant src/probe.sh 'cp -f "${file}" "${file%.*}.bak"'

  # Act
  check

  # Assert
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"src/probe.sh:1: a backup name drops the extension of the file it keeps"* ]]
}

@test "check-names - reports a bare wait in a test" {
  # Arrange
  plant test/probe.bats '  wait'

  # Act
  check

  # Assert
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"test/probe.bats:1: a bare wait also waits for bats' timeout watchdog"* ]]
}
