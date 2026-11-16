#!/usr/bin/env bash

REVAMPED_TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

harness_setup() {
  REVAMPED_TEST_TMUX_DIR="$(mktemp -d "${BATS_TEST_TMPDIR:-${TMPDIR:-/tmp}}/tmux-store.XXXXXX")"
  REVAMPED_TEST_TMUX_LOG="${REVAMPED_TEST_TMUX_DIR}.log"
  : >"${REVAMPED_TEST_TMUX_LOG}"
  export REVAMPED_TEST_TMUX_DIR REVAMPED_TEST_TMUX_LOG
  PATH="${REVAMPED_TESTS_DIR}/bin:${PATH}"
  export PATH
}

lib_call() {
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/call.sh" "$@"
}

tmux_answer() {
  printf '%s' "$2" >"${REVAMPED_TEST_TMUX_DIR}/$(printf '%s' "display.${3:--}.$1" | tr -c 'A-Za-z0-9_.-' '_')"
}

tmux_calls() {
  cat "${REVAMPED_TEST_TMUX_LOG}"
}
