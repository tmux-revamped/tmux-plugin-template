# tmux-plugin-template

Guidance for anyone, human or agent, changing tmux-plugin-template. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything the template shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to the template, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into the family file instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`lib/`](lib) | The shared library every member carries. Every file there except `core.sh` is identical in every member |
| [`lib/core.sh`](lib/core.sh) | The template's version and constants |
| [`test/`](test) | The shared library's suites, identical in every member, and the CI scripts' suites, such as [`test/recover.bats`](test/recover.bats) |
| [`test/docs.bats`](test/docs.bats) | The README link check |
| [`.github/scripts/`](.github/scripts) | The scripts only CI and the release run: version stamping, CI state and recovery |

## Names

- The template has no tmux options, placeholders or keys of its own.
- Its constants carry `TMUX_PLUGIN_`, and the version constant is `TMUX_PLUGIN_TEMPLATE_VERSION`.
- Its command-line tool, once it exists, is `template-revamped`.

## Behaviour

- The template is not a plugin anyone installs. It is the base a new member starts from, and a member of the family itself, so its identical files match every other member's.
- It has no `.tmux` entry point, so the audit finds no entry point to check here.

## Domain rules

- Shared work starts here when no member's feature needs it, because no plugin code competes with it, and is copied into every other member in the same task.
- A new member is scaffolded from this repository, so anything a new member must carry from its first commit lives here.

## Release

- `TMUX_PLUGIN_TEMPLATE_VERSION` in [`lib/core.sh`](lib/core.sh) holds the version. Nobody edits it by hand.
- After a green `ci` run on `main`, [`release.yml`](.github/workflows/release.yml) runs semantic-release: a `feat` or `fix` since the last tag publishes a release, [`set-version.sh`](.github/scripts/set-version.sh) stamps the constant, and the notes go into [`CHANGELOG.md`](CHANGELOG.md).

## Gaps against FAMILY.md

As of 2026-11-15:

- There is no `bin/template-revamped`.
- No `template-revamped` command with `help`, `version` and `doctor` in the family's form, no man page, no completions and no `manifest.json`.
- No `make new-member NAME=<name>` scaffold.
- No gum interface: no `lib/ui.sh`, `lib/table.awk`, themes or `test/bin/gum`.
- No `screens/`: no VHS recording of each feature, no on-screen caption of the keys each recording presses, and no recordings in the README.
- The README sections are not the family's order of Quick start, Usage, topic sections, Portability, Development and License.
- No golden transcripts.
- The Makefile has no `screens` or `install` target, and `make lint` runs no `mandoc -T lint`, since there is no command, man page or screen yet.
