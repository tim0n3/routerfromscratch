SHELL := /usr/bin/env bash

SH_FILES := $(shell ls *.sh 2>/dev/null)

.PHONY: init fmt lint test build scan ci

init:
	@if command -v mise >/dev/null 2>&1; then mise install; else echo "mise not installed (see https://mise.jdx.dev)"; fi
	@if command -v pre-commit >/dev/null 2>&1; then pre-commit install; else echo "pre-commit not installed (pipx install pre-commit)"; fi

fmt:
	@if [ -n "$(SH_FILES)" ]; then \
		if command -v shfmt >/dev/null 2>&1; then shfmt -w -s $(SH_FILES); \
		else echo "shfmt not installed"; exit 1; fi; \
	else echo "No shell files to format."; fi

lint:
	@if [ -z "$(SH_FILES)" ]; then \
		echo "No shell files to lint."; \
	elif command -v pre-commit >/dev/null 2>&1; then \
		pre-commit run shellcheck --all-files; \
	elif command -v shellcheck >/dev/null 2>&1; then \
		shellcheck $(SH_FILES); \
	else \
		echo "shellcheck not installed"; \
		exit 1; \
	fi

test:
	@echo "No tests defined."

build:
	@echo "No build step defined."

scan:
	@if command -v gitleaks >/dev/null 2>&1; then gitleaks detect --source . --no-git --redact; else echo "gitleaks not installed"; fi
	@if command -v semgrep >/dev/null 2>&1; then semgrep --config auto --error --quiet; else echo "semgrep not installed"; fi
	@if [ -f Dockerfile ] || ls docker-compose*.yml >/dev/null 2>&1; then \
		if command -v trivy >/dev/null 2>&1; then trivy fs --exit-code 1 --severity HIGH,CRITICAL .; else echo "trivy not installed"; fi; \
		if command -v syft >/dev/null 2>&1; then syft dir:.; else echo "syft not installed"; fi; \
	else echo "No Docker files detected; skipping trivy/syft."; fi

ci: lint test
