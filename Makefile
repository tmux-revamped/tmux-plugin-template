SHELL := /bin/sh
SCRIPTS = $(shell git ls-files -- '*.sh' '*.bash' '*.bats' '*.tmux')
POSIX_SCRIPTS = $(shell git ls-files -- 'lib/*.sh' '*.tmux' '.github/scripts/*.sh' 'test/*.sh' 'test/bin/*')
TEST_SCRIPTS = $(shell git ls-files -- 'test/*.bash' 'test/*.bats')

.PHONY: help fmt lint test test-all test-linux coverage check clean

help:
	@echo "targets:"
	@echo "  fmt         format every script with shfmt -i 2"
	@echo "  lint        shfmt, ShellCheck, yamllint and actionlint at zero findings"
	@echo "  test        the bats suites under the system sh"
	@echo "  test-all    the bats suites under every installed shell, both builds of bash and zsh on macOS"
	@echo "  test-linux  the bats suites in an Ubuntu container"
	@echo "  coverage    bashcov on this Mac and in the Ubuntu container, merged, gate 100%"
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
	sh test/linux-container.sh sh test/run-matrix.sh

coverage:
	sh scripts/coverage.sh 0 && cp -f coverage/.resultset.json coverage-macos.json
	sh test/linux-container.sh sh scripts/linux-coverage.sh
	python3 scripts/coverage-gate.py '/lib/[a-z]+\.sh\Z' 100 coverage-macos.json coverage-linux.json

check: lint test

clean:
	rm -rf coverage coverage-macos.json coverage-linux.json coverage-linux-warnings.log
