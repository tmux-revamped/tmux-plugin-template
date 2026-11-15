#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
cd "${root}"
max_lines=500
allowlist=.github/file-size-allowlist
failed=0

complain() {
  printf '%s\n' "$1" >&2
  failed=1
}

sources() {
  git ls-files -- 'src/*.sh'
}

check_shebangs() {
  for file in $(sources); do
    first=$(head -n 1 "${file}")
    [ "${first}" = '#!/usr/bin/env bash' ] || complain "${file}: the first line is not #!/usr/bin/env bash"
  done
}

check_guards() {
  guards=$(sources | xargs grep -hoE '^_[A-Z_]+_LOADED=1' | sed 's/=1$//' | LC_ALL=C sort -u)
  [ -n "${guards}" ] || return 0
  unsets=$(git ls-files -- 'test/*' | xargs grep -hoE 'unset _[A-Z_]+_LOADED' | sed 's/^unset //' | LC_ALL=C sort -u)
  for guard in ${guards}; do
    printf '%s\n' "${unsets}" | grep -qxF "${guard}" || complain "${guard}: a source guard the test helpers never unset"
  done
}

allowed_lines() {
  limit=${max_lines}
  if [ -f "${allowlist}" ]; then
    listed=$(awk -v f="$1" '$1 == f { print $2 }' "${allowlist}")
    [ -z "${listed}" ] || limit=${listed}
  fi
  printf '%s\n' "${limit}"
}

check_sizes() {
  for file in $(sources); do
    lines=$(awk 'END { print NR }' "${file}")
    limit=$(allowed_lines "${file}")
    [ "${lines}" -le "${limit}" ] || complain "${file}: ${lines} lines, more than ${limit}"
  done
}

check_documented_options() {
  slug=$(basename "${root}" | sed 's/^tmux-//; s/-revamped$//')
  files=$(sources)
  options=$(printf '%s\n' "${files}" | xargs grep -hoE "@${slug}_revamped_[a-z_]+" | LC_ALL=C sort -u)
  for option in ${options}; do
    grep -qF -- "${option}" README.md || complain "${option}: not documented in README.md"
  done
}

check_version() {
  constant=$(grep -hoE '^readonly [A-Z_]*(_REVAMPED|TMUX_PLUGIN_TEMPLATE)_VERSION="[0-9.]+"$' src/lib/utils/constants.sh | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
  changelog=$(grep -m 1 -E '^##? \[[0-9]' CHANGELOG.md | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)
  [ -n "${constant}" ] || complain "src/lib/utils/constants.sh: no version constant"
  [ "${constant}" = "${changelog}" ] || complain "the version constant ${constant} differs from the newest CHANGELOG.md release ${changelog}"
}

check_shebangs
check_guards
check_sizes
check_documented_options
check_version
exit "${failed}"
