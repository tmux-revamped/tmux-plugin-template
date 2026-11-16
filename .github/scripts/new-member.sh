#!/bin/sh
set -eu

die() {
  printf 'new-member: %s\n' "$1" >&2
  exit 1
}

check_arguments() {
  case "$1" in
  '') die "give the plugin a name: make new-member NAME=example" ;;
  *[!a-z0-9-]* | -* | *- | *--* | [0-9]*) die "a name is lowercase letters, digits and single hyphens, such as clipboard or git-status, got: $1" ;;
  template) die "template is the name of this repository" ;;
  *) ;;
  esac
  [ -n "$2" ] || die "give the destination: make new-member NAME=example DEST=../tmux-example-revamped"
  [ ! -e "$2" ] || die "$2 already exists"
}

copy_tracked() {
  copy_tracked_files=$(git -C "$1" ls-files)
  printf '%s\n' "${copy_tracked_files}" | while IFS= read -r copy_tracked_file; do
    case "${copy_tracked_file}" in
    README*.md | CHANGELOG.md | screens/*.png | screens/*.gif | .github/scripts/new-member.sh | test/new-member.bats) continue ;;
    *) ;;
    esac
    copy_tracked_target=$(printf '%s\n' "${copy_tracked_file}" | sed "s/template-revamped/$3-revamped/g")
    mkdir -p "$2/$(dirname "${copy_tracked_target}")"
    cp -p "$1/${copy_tracked_file}" "$2/${copy_tracked_target}"
  done
}

rename_names() {
  rename_names_lower=$(printf '%s' "$2" | tr '-' '_')
  rename_names_upper=$(printf '%s' "${rename_names_lower}" | tr '[:lower:]' '[:upper:]')
  rename_names_title=$(printf '%s' "$2" | tr '[:lower:]' '[:upper:]')
  git -C "$1" ls-files --others | while IFS= read -r rename_names_file; do
    case "${rename_names_file}" in
    FAMILY.md | .github/scripts/set-version.sh) continue ;;
    *) ;;
    esac
    sed -e "s/TMUX_PLUGIN_TEMPLATE_/${rename_names_upper}_REVAMPED_/g" \
      -e "s/TEMPLATE_REVAMPED/${rename_names_upper}_REVAMPED/g" \
      -e "s/TEMPLATE-REVAMPED/${rename_names_title}-REVAMPED/g" \
      -e "s/template_revamped/${rename_names_lower}_revamped/g" \
      -e "s/template-revamped/$2-revamped/g" \
      -e "s/tmux-plugin-template/tmux-$2-revamped/g" \
      "$1/${rename_names_file}" >"$1/${rename_names_file}.new"
    cat "$1/${rename_names_file}.new" >"$1/${rename_names_file}"
    rm -f "$1/${rename_names_file}.new"
  done
}

reset_version() {
  sed 's/^\(readonly [A-Z_]*_REVAMPED_VERSION=\)"[0-9.]*"$/\1"0.0.0"/' "$1/lib/core.sh" >"$1/lib/core.sh.new"
  mv -f "$1/lib/core.sh.new" "$1/lib/core.sh"
}

write_readme() {
  {
    printf '# tmux-%s-revamped\n\n' "$3"
    sed -n '/^<!-- family:begin -->$/,/^<!-- family:end -->$/p' "$1/README.md" | sed 's/\*\*this plugin\*\*, //'
  } >"$2/README.md"
}

drop_scaffold_target() {
  awk '/^\.PHONY:/ { sub(/ new-member/, "") } /^NAME \?=|^DEST \?=|^new-member:|^\t@echo "  new-member/ { skip = /^new-member:/; next } skip { skip = 0; next } { print }' "$1/Makefile" >"$1/Makefile.new"
  mv -f "$1/Makefile.new" "$1/Makefile"
}

write_agent_guide() {
  {
    printf '# tmux-%s-revamped\n\n' "$2"
    printf 'Guidance for anyone, human or agent, changing tmux-%s-revamped. [FAMILY.md](FAMILY.md) holds everything it shares with the rest of the family.\n' "$2"
    awk '/^## Gaps against FAMILY.md$/ { exit } /^## / { print ""; print }' "$1/AGENTS.md"
    printf '\n## Gaps against FAMILY.md\n\n- The README holds only its title and the family section.\n- No plugin entry point.\n- No screens recorded.\n'
  } >"$3/AGENTS.md"
}

main() {
  main_root=$(cd "$(dirname "$0")/../.." && pwd)
  check_arguments "$1" "$2"
  git -C "${main_root}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "${main_root} is not a git checkout, so there is no list of files to copy"
  mkdir -p "$2"
  git -C "$2" init -q -b main
  copy_tracked "${main_root}" "$2" "$1"
  rename_names "$2" "$1"
  drop_scaffold_target "$2"
  reset_version "$2"
  write_readme "${main_root}" "$2" "$1"
  write_agent_guide "${main_root}" "$1" "$2"
  git -C "$2" add -A
  printf 'new-member: tmux-%s-revamped is ready in %s\n' "$1" "$2"
}

main "${1:-}" "${2:-}"
