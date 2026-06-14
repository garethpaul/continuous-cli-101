.PHONY: audit build check lint test verify

NPM ?= npm
override ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

lint:
	$(NPM) --prefix $(ROOT) run lint

test:
	$(NPM) --prefix $(ROOT) test

build:
	$(NPM) --prefix $(ROOT) run check

audit:
	$(NPM) --prefix $(ROOT) run audit

verify: lint test build audit

check: verify
