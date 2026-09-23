<div align="center">

<h1>tmux-plugin-template</h1>

**A template for building non-blocking tmux status plugins.**

[![Tests](https://github.com/tmux-revamped/tmux-plugin-template/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-plugin-template/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](CHANGELOG.md)

</div>

**54** tests · **95%+** coverage · **2** platforms · **0** temp files

This is the shared foundation for the `tmux-*-revamped` status plugins. It provides an async, temp-file-free cache that keeps all state in tmux server user-options, so the status bar reads a cached value instantly while a detached worker recomputes stale values in the background. It also ships platform helpers, a bats test harness that runs on bash 3.2, kcov coverage tooling, and CI.

<table>
<tr>
<td width="50%">

### Non-blocking cache

The hot path reads a cached tmux user-option and returns at once; a detached worker recomputes the value when it goes stale.

</td>
<td width="50%">

### No temp files

All state lives in tmux server options, so nothing touches the filesystem.

</td>
</tr>
<tr>
<td width="50%">

### bash 3.2 compatible

The test harness runs on the macOS system bash without a newer interpreter.

</td>
<td width="50%">

### Coverage enforced

CI runs a kcov gate that fails below 95%.

</td>
</tr>
</table>

## Use this template

On GitHub, click "Use this template" to generate a new repository from this one, or run `gh repo create <owner>/tmux-<metric>-revamped --template <owner>/tmux-plugin-template`.

A plugin built from the template follows the layout the shared core expects: source the cache from [`src/lib/utils/cache.sh`](src/lib/utils/cache.sh), set a `CACHE_PREFIX` to namespace its options, add per-platform parsers under [`src/lib`](src/lib), and add one bats file per module under [`test/`](test) at 95%+ coverage. See [`examples/`](examples) for a worked dispatcher and worker.

## Structure

The shared shell modules live under [`src/`](src) and their tests under [`test/`](test).

```
src/
  lib/
    tmux/
      tmux-ops.sh        tmux option get, set, and unset
    utils/
      cache.sh           async, temp-file-free cache
      platform.sh        memoized OS detection
      has-command.sh     command availability probe
      error-logger.sh    opt-in logging, off by default
      constants.sh       shared defaults
test/                    bats suites, helpers, and tmux mock
examples/                worked dispatcher and worker
.github/                 Tests workflow and CI
Makefile                 test, lint, and coverage targets
```

## Development

| Command | Description |
|---------|-------------|
| `make test` | Run the full test suite |
| `make test-unit` | Run unit tests only |
| `make coverage` | Measure line coverage with kcov and enforce the minimum, Linux only |
| `make lint` | Run shellcheck on all shell files |
| `make clean` | Remove coverage and temp artifacts |
| `make help` | Show available targets |

## License

[MIT](LICENSE), copyright Gustavo Franco.

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the
same contract in [`FAMILY.md`](FAMILY.md), the same tooling under `family/`, and
the same shared library, all held byte-identical by a checksum manifest. They are
built to be installed together: no member claims a key or a tmux option that
another member claims.

A defect found in one member is hunted across all of them before the fix is
called done. That obligation is written into the contract rather than left to
memory, and `family/bin/sweep` is how it is discharged.

| Member | What it does |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | Edit your tmux config, save, and watch it reload itself, no key, no command |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | Battery status for your tmux status bar, without ever blocking the status render |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | Every connected Bluetooth device and its battery in your tmux status bar, without blocking the render |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPU load, temperature, and frequency in your tmux status bar, without ever blocking the render |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | Disk usage for your tmux status bar, without ever blocking the status render |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Fuzzy-grab any URL, path, or word off the screen and paste it, pure shell, no Python |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Jump to any session, window, or pane, or kill it, from one fzf popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Git repository status in your tmux status bar, without ever blocking the render |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, frequency, and memory for your tmux status bar |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | Current Kubernetes context and namespace in your tmux status bar, async, kubectl-free, never blocking |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Launch any TUI app in a popup or a window, scoped to the current pane's directory, with one configurable bindi |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Standard pane and window management bindings for tmux, version aware, vim friendly, and fully configurable |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | One plugin that captures every session, window, pane, layout, and working |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | **this plugin**, A template for building non-blocking tmux status plugins |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in your tmux status bar, with zero temp files: all state lives in tmux options |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM usage for your tmux status bar, without ever blocking the status render |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Mouse wheel that does the right thing: scroll the app directly, copy-mode everywhere else. No app names to con |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults that normalize behavior across every tmux version, OS, and terminal, without clobbering |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | --- |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local clock and world clocks in your tmux status bar, without ever blocking the render |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather in your tmux status bar, fetched in the background so the render never waits on the network |

### Checking an installation

With every member on disk, one command reports any conflict between them:

```sh
family/bin/doctor --live
```

It reads each member and the running tmux server, and reports duplicate keys,
duplicate status placeholders, options outside the naming grammar, and any
member whose contract version has fallen behind.

<!-- family:end -->
