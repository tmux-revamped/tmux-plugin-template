#!/usr/bin/env bats

setup() {
  SOURCE_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  REPO="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "${REPO}/scripts" "${REPO}/.github/workflows"
  cp -f "${SOURCE_ROOT}/scripts/check-pins.sh" "${REPO}/scripts/check-pins.sh"
  git -C "${REPO}" init --quiet
}

write_step() {
  printf 'jobs:\n  probe:\n    steps:\n      - uses: %s\n' "${1}" >"${REPO}/.github/workflows/probe.yml"
  git -C "${REPO}" add --all
}

check() {
  run sh "${REPO}/scripts/check-pins.sh"
}

@test "check-pins - accepts an action pinned to a full commit sha" {
  # Arrange
  write_step 'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1  # v7.0.1'

  # Act
  check

  # Assert
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

@test "check-pins - accepts an image pinned to a digest" {
  # Arrange
  write_step 'docker://ghcr.io/zizmorcore/zizmor:1.30.1@sha256:a2eb396d886c053073405c7a980f2139ba2248ec172243cfa3841e57196e8101'

  # Act
  check

  # Assert
  [ "${status}" -eq 0 ]
}

@test "check-pins - accepts a local action" {
  # Arrange
  write_step './.github/actions/probe'

  # Act
  check

  # Assert
  [ "${status}" -eq 0 ]
}

@test "check-pins - reports an action pinned to a tag" {
  # Arrange
  write_step 'actions/checkout@v7.0.1'

  # Act
  check

  # Assert
  [ "${status}" -eq 1 ]
  [[ "${output}" == *".github/workflows/probe.yml:4: actions/checkout@v7.0.1"* ]]
}

@test "check-pins - reports an action pinned to a short sha" {
  # Arrange
  write_step 'actions/checkout@3d3c42e'

  # Act
  check

  # Assert
  [ "${status}" -eq 1 ]
  [[ "${output}" == *".github/workflows/probe.yml:4: actions/checkout@3d3c42e"* ]]
}

@test "check-pins - reports an image without a digest" {
  # Arrange
  write_step 'docker://alpine:3.22'

  # Act
  check

  # Assert
  [ "${status}" -eq 1 ]
  [[ "${output}" == *".github/workflows/probe.yml:4: docker://alpine:3.22"* ]]
}
