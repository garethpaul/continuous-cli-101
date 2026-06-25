#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)

node "$ROOT_DIR/scripts/check-descriptor-discovery-bundle.js"
node "$ROOT_DIR/scripts/test-descriptor-discovery.js"
printf '%s\n' 'Descriptor discovery truncation, child-failure, framing, and auto-backend tests passed.'
