SHELL := /bin/sh
SCRIPTS = $(shell git ls-files -- '*.sh' '*.bash' '*.bats' '*.tmux' 'family/bin/*')
BASH_SOURCES = $(shell git ls-files -- 'src/*.sh' '*.tmux' '*.bash' 'family/bin/*' 'family/lib/*.sh' 'test/*.sh')
POSIX_SCRIPTS = $(shell git ls-files -- '.github/scripts/*.sh' 'scripts/*.sh')
LINUX_IMAGE := ubuntu:26.04
LINUX_PACKAGES := bats git make tmux zsh kcov python3 ca-certificates
COVERAGE_MIN := 95
CONTAINER_DIR := /src/$(notdir $(CURDIR))

.PHONY: help fmt lint test test-all test-linux coverage coverage-kcov check clean

help:
	@echo "targets:"
	@echo "  fmt         format every script with shfmt -i 2"
	@echo "  lint        shfmt, ShellCheck, the name, source and pin checks, yamllint and actionlint at zero findings"
	@echo "  test        the bats suites"
	@echo "  test-all    the bats suites with every installed bash and zsh as the login shell"
	@echo "  test-linux  the bats suites in an Ubuntu container"
	@echo "  coverage    kcov in an Ubuntu container, gate $(COVERAGE_MIN)%"
	@echo "  check       lint and test"
	@echo "  clean       remove the coverage output"

fmt:
	shfmt -i 2 -w $(SCRIPTS)

lint:
	shfmt -i 2 -d $(SCRIPTS)
	shellcheck -x --severity=warning --shell=bash $(BASH_SOURCES)
	shellcheck -x -o all -s sh $(POSIX_SCRIPTS)
	sh scripts/check-names.sh
	sh scripts/check-source.sh
	sh scripts/check-pins.sh
	yamllint -s -c .yamllint.yml .github .yamllint.yml
	actionlint

test:
	bats --recursive test/

test-all:
	@set -e; seen=; \
	for login in /bin/bash /bin/zsh $$(command -v bash) $$(command -v zsh); do \
	  [ -x "$$login" ] || continue; \
	  case " $$seen " in *" $$login "*) continue ;; esac; \
	  seen="$$seen $$login"; \
	  echo "== login shell $$login"; \
	  SHELL="$$login" bats --recursive test/; \
	done

test-linux:
	docker run --rm -v "$(CURDIR):$(CONTAINER_DIR)" -w $(CONTAINER_DIR) $(LINUX_IMAGE) sh -c '\
	  set -e; \
	  apt-get update -qq >/dev/null; \
	  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $(LINUX_PACKAGES) >/dev/null; \
	  git config --global --add safe.directory $(CONTAINER_DIR); \
	  bats --recursive test/'

coverage:
	docker run --rm -v "$(CURDIR):$(CONTAINER_DIR)" -w $(CONTAINER_DIR) $(LINUX_IMAGE) sh -c '\
	  set -e; \
	  apt-get update -qq >/dev/null; \
	  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $(LINUX_PACKAGES) >/dev/null; \
	  git config --global --add safe.directory $(CONTAINER_DIR); \
	  make coverage-kcov'

coverage-kcov:
	rm -rf coverage
	kcov "--include-path=$(CURDIR)/src" coverage bats --recursive test/
	python3 -c "import glob, json, sys; \
files = sorted(glob.glob('coverage/kcov-merged/coverage.json') or glob.glob('coverage/*/coverage.json')); \
percent = float(json.load(open(files[-1]))['percent_covered']) if files else 0.0; \
print(f'Line coverage: {percent}% (min $(COVERAGE_MIN)%)'); \
sys.exit(0 if percent >= $(COVERAGE_MIN) else 1)"

check: lint test

clean:
	rm -rf coverage
