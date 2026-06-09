.PHONY: audit build check lint test verify

NPM ?= npm

lint:
	$(NPM) run lint

test:
	$(NPM) test

build:
	$(NPM) run check

audit:
	$(NPM) run audit

verify: lint test build audit

check: verify
