SHELL := bash
SCRIPTS := install.sh tests/contracts/validate.sh

.PHONY: verify check lint test help
.DEFAULT_GOAL := help

help: ## list targets
	@grep -hE '^[a-z]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/\t/' | sort

check: lint ## fast loop

verify: lint test ## full gate (run before shipping)

lint: ## bash -n on every script + shellcheck when available
	@for f in $(SCRIPTS); do bash -n "$$f" && echo "  ✓ syntax $$f"; done
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck $(SCRIPTS) && echo "  ✓ shellcheck"; \
	else echo "  – shellcheck not installed, skipped"; fi

test: ## metadata, contract, and installer sanity
	@out=$$(bash install.sh --help); echo "$$out" | grep -q 'install.sh' \
		&& ! echo "$$out" | grep -q 'fetching tlahcuilo' \
		&& echo "  ✓ local --help works and does not clone"
	@out=$$(bash install.sh --help); \
		if echo "$$out" | grep -qE '^(set |[A-Z_]+=)'; then \
			echo "  ✗ --help leaks script body (line range in the -h case is off)"; exit 1; \
		else echo "  ✓ --help prints only the header comment"; fi
	@bash tests/contracts/validate.sh
