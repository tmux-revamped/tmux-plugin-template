# tmux-plugin-template

Guidance for anyone, human or agent, changing tmux-plugin-template. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything the template shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to the template, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into the family file instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`src/lib/utils/`](src/lib/utils), [`src/lib/tmux/`](src/lib/tmux) | The shared library every member carries. Every file there except `constants.sh` is owned by the family |
| [`src/lib/utils/constants.sh`](src/lib/utils/constants.sh) | The template's constants, including its version |
| [`test/lib/`](test/lib) | The shared library's suite, owned |
| [`test/family/`](test/family) | The family tooling's suite, owned |
| [`test/docs.bats`](test/docs.bats) | The README link check |
| [`family/`](family) | The family tooling, owned |

## Names

- The template has no tmux options, placeholders or keys of its own.
- Its constants carry `TMUX_PLUGIN_`, and the version constant is `TMUX_PLUGIN_TEMPLATE_VERSION`.
- Its command-line tool, once it exists, is `template-revamped`.

## Behaviour

- The template is not a plugin anyone installs. It is the base a new member starts from, and a member of the family itself, so its owned files stay identical to every other member's.
- It has no `.tmux` entry point, so the audit finds no entry point to check here.

## Domain rules

- Shared work starts here when no member's feature needs it, because no plugin code competes with it, and reaches the other members through [`family/bin/propagate`](family/bin/propagate).
- A new member is scaffolded from this repository, so anything a new member must carry from its first commit lives here.

## Release

- `TMUX_PLUGIN_TEMPLATE_VERSION` in [`src/lib/utils/constants.sh`](src/lib/utils/constants.sh) holds the version. It must equal the newest versioned heading in [`CHANGELOG.md`](CHANGELOG.md) and the README's version badge, which the `version` job in `tests.yml` checks.
- A push to `main` whose version has no tag yet makes the `release` job in `tests.yml` tag `vX.Y.Z` and publish a GitHub release with that changelog section.

## Gaps against FAMILY.md

As of 2026-11-15:

- Every script is bash, under `#!/usr/bin/env bash`, not POSIX `sh`, so it is untested under `dash`, `zsh` and BusyBox `sh`.
- The code lives under the source tree's library folder; there is no `bin/template-revamped`, `lib/state.sh` or `lib/core.sh`.
- No `template-revamped` command with `help`, `version` and `doctor` in the family's form, no man page, no completions and no `manifest.json`.
- No `make new-member NAME=<name>` scaffold.
- No gum interface: no `lib/ui.sh`, `lib/table.awk`, themes or `test/bin/gum`.
- No `screens/` and no recordings in the README.
- The README sections are not the family's order of Quick start, Usage, topic sections, Portability, Development and License.
- Coverage is kcov with a 95 percent floor on Linux, not bashcov at 100 percent merged from macOS and Linux.
- CI tests GNU, BSD and uutils tools in `tests.yml`, but not the six toolsets through `.github/scripts/toolset.sh`, and no shell matrix under `sh`, `dash`, `bash` and `zsh`.
- No golden transcripts, `call.sh`, `run-matrix.sh` or `linux-container.sh`.
- The version is written by hand and released by `tests.yml`; there is no semantic-release, `package.json`, `release.yml` with `recover`, `bot-merge.yml` or Renovate.
- CI is `tests.yml`, `family.yml` and `security.yml`, not `ci.yml`, and no job starts with `step-security/harden-runner`.
- The pull request template, `labeler.yml`, `pr.yml` and `stale.yml` are still present.
- No `.editorconfig`, `.yamllint.yml`, `scripts/check-names.sh` or shfmt; the Makefile has `help`, `test`, `test-unit`, `coverage`, `lint` and `clean`, not the family's targets.
- The family tooling is bash, so running the audit under `dash` fails.
