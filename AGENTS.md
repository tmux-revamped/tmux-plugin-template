# tmux-plugin-template

Guidance for anyone, human or agent, changing tmux-plugin-template. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything the template shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to the template, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into the family file instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`bin/template-revamped`](bin/template-revamped) | The command-line tool: `help`, `version`, `doctor` and the menu |
| [`man/template-revamped.1`](man/template-revamped.1) | The man page |
| [`completions/`](completions) | Completions for bash, zsh and fish |
| [`lib/`](lib) | The shared library every member carries. Every file there except `core.sh` is identical in every member |
| [`lib/core.sh`](lib/core.sh) | The template's version and constants |
| [`test/`](test) | The shared library's suites, identical in every member, and the CI scripts' suites, such as [`test/recover.bats`](test/recover.bats) |
| [`test/docs.bats`](test/docs.bats) | The README link check |
| [`.github/scripts/`](.github/scripts) | The scripts only CI and the release run: version stamping, CI state and recovery |

## Names

- The template has no tmux options, placeholders or keys of its own.
- Its constants carry `TMUX_PLUGIN_`, and the version constant is `TMUX_PLUGIN_TEMPLATE_VERSION`.
- Its command-line tool is `template-revamped`, and its environment settings are `TEMPLATE_REVAMPED_THEME` and `TEMPLATE_REVAMPED_ACCENT`.

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

As of 2026-11-16:

- No `make new-member NAME=<name>` scaffold.
- No `screens/`: no VHS recording of each feature, no on-screen caption of the keys each recording presses, and no recordings in the README.
- The README sections are not the family's order of Quick start, Usage, topic sections, Portability, Development and License.
- No golden transcripts.
- The Makefile has no `screens` target, since there is no screen yet.
