SHELL := /bin/sh
SCRIPTS = $(shell git ls-files -- '*.sh' '*.bash' '*.bats' '*.tmux')
POSIX_SCRIPTS = $(shell git ls-files -- 'lib/*.sh' '*.tmux' '.github/scripts/*.sh' 'test/*.sh' 'test/bin/*')
TEST_SCRIPTS = $(shell git ls-files -- 'test/*.bash' 'test/*.bats')
LINUX_IMAGE := ubuntu:26.04
LINUX_PACKAGES := bats dash git make tmux zsh kcov python3 ca-certificates
COVERAGE_MIN := 95
CONTAINER_DIR := /src/$(notdir $(CURDIR))

.PHONY: help fmt lint test test-all test-linux coverage coverage-kcov check clean

help:
	@echo "targets:"
	@echo "  fmt         format every script with shfmt -i 2"
	@echo "  lint        shfmt, ShellCheck, yamllint and actionlint at zero findings"
	@echo "  test        the bats suites under the system sh"
	@echo "  test-all    the bats suites under every installed shell, both builds of bash and zsh on macOS"
	@echo "  test-linux  the bats suites in an Ubuntu container"
	@echo "  coverage    kcov in an Ubuntu container, gate $(COVERAGE_MIN)%"
	@echo "  check       lint and test"
	@echo "  clean       remove the coverage output"

fmt:
	shfmt -i 2 -w $(SCRIPTS)

lint:
	shfmt -i 2 -d $(SCRIPTS)
	shellcheck -x -o all -s sh $(POSIX_SCRIPTS)
	shellcheck -x -o all $(TEST_SCRIPTS)
	yamllint -s -c .yamllint.yml .github .yamllint.yml
	actionlint

test:
	REVAMPED_TEST_SHELLS=sh sh test/run-matrix.sh

test-all:
	sh test/run-matrix.sh

test-linux:
	docker run --rm -v "$(CURDIR):$(CONTAINER_DIR)" -w $(CONTAINER_DIR) $(LINUX_IMAGE) sh -c '\
	  set -e; \
	  apt-get update -qq >/dev/null; \
	  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $(LINUX_PACKAGES) >/dev/null; \
	  git config --global --add safe.directory $(CONTAINER_DIR); \
	  sh test/run-matrix.sh'

coverage:
	docker run --rm -v "$(CURDIR):$(CONTAINER_DIR)" -w $(CONTAINER_DIR) $(LINUX_IMAGE) sh -c '\
	  set -e; \
	  apt-get update -qq >/dev/null; \
	  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $(LINUX_PACKAGES) >/dev/null; \
	  git config --global --add safe.directory $(CONTAINER_DIR); \
	  make coverage-kcov'

coverage-kcov:
	rm -rf coverage
	kcov "--include-path=$(CURDIR)/lib" coverage bats --recursive test/
	python3 -c "import glob, json, sys; \
files = sorted(glob.glob('coverage/kcov-merged/coverage.json') or glob.glob('coverage/*/coverage.json')); \
percent = float(json.load(open(files[-1]))['percent_covered']) if files else 0.0; \
print(f'Line coverage: {percent}% (min $(COVERAGE_MIN)%)'); \
sys.exit(0 if percent >= $(COVERAGE_MIN) else 1)"

check: lint test

clean:
	rm -rf coverage
