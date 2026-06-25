#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
destination=$1
parent=$(dirname -- "$destination")
name=$(basename -- "$destination")

mkdir -p -- "$parent"
staging=$(mktemp -d "$parent/.${name}.copy.XXXXXX")
list=$(mktemp "${TMPDIR:-/tmp}/continuous-cli-tracked-list.XXXXXX")
archive=$(mktemp "${TMPDIR:-/tmp}/continuous-cli-tracked-archive.XXXXXX")

cleanup() {
  rm -rf -- "$staging"
  rm -f -- "$list" "$archive"
}
trap cleanup EXIT HUP INT TERM

git -C "$ROOT_DIR" ls-files -z >"$list"
(
  CDPATH='' cd -- "$ROOT_DIR"
  tar --null -T "$list" -cf "$archive"
)
(
  CDPATH='' cd -- "$staging"
  tar -xf "$archive"
)

rm -rf -- "$destination"
mv -- "$staging" "$destination"
trap - EXIT HUP INT TERM
rm -f -- "$list" "$archive"
