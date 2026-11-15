#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
cd "${root}"

forbidden=$(git ls-files -z -- '*.sh' '*.tmux' 'family/bin/*' | xargs -0 awk '
  /\$\(dd / && !/tr -d/ { print FILENAME ":" FNR ": a dd read into a variable keeps its NUL bytes" }
  /^[[:space:]]*\}[[:space:]]*>/ { print FILENAME ":" FNR ": a brace group closes on a redirect bashcov cannot count" }
  /done[[:space:]]+[0-9]+</ { print FILENAME ":" FNR ": a loop redirects a fixed descriptor bashcov can take" }
  /function[[:space:]]+(xor|and|or|compl|lshift|rshift|strftime|systime)[[:space:]]*\(/ { print FILENAME ":" FNR ": an awk function is named like a gawk built-in" }
  /while[[:space:]]+![[:space:]]+mkdir/ { print FILENAME ":" FNR ": a lock is taken with mkdir" }
  /wc -c[[:space:]]*</ { print FILENAME ":" FNR ": a file size is read with wc, which BusyBox counts in 32 bits" }
  /%\.\*\}\.bak|\$\/\.bak\// { print FILENAME ":" FNR ": a backup name drops the extension of the file it keeps" }
')
if [ -n "${forbidden}" ]; then
  printf 'code FAMILY.md forbids:\n%s\n' "${forbidden}" >&2
  exit 1
fi

waits=$(git ls-files -z -- '*.bats' '*.bash' | xargs -0 awk '/^[[:space:]]*wait[[:space:]]*$/ { print FILENAME ":" FNR ": a bare wait also waits for bats'"'"' timeout watchdog" }')
if [ -n "${waits}" ]; then
  printf 'tests FAMILY.md forbids:\n%s\n' "${waits}" >&2
  exit 1
fi
