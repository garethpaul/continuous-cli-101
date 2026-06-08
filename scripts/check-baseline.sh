#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PACKAGE_JSON="$ROOT_DIR/package.json"
PACKAGE_LOCK="$ROOT_DIR/package-lock.json"
WORKFLOW="$ROOT_DIR/.github/workflows/main.yml"
README="$ROOT_DIR/README.md"
PLAN="$ROOT_DIR/docs/plans/2026-06-08-twilio-function-test-baseline.md"

require_file() {
  path=$1
  if [ ! -f "$ROOT_DIR/$path" ]; then
    printf '%s\n' "Required file is missing: $path" >&2
    exit 1
  fi
}

for path in \
  ".nvmrc" \
  "README.md" \
  "package.json" \
  "package-lock.json" \
  ".github/workflows/main.yml" \
  "CHANGES.md" \
  "assets/message.private.js" \
  "functions/hello-world.js" \
  "functions/private-message.js" \
  "functions/sms/reply.protected.js" \
  "scripts/test-functions.js" \
  "docs/plans/2026-06-08-twilio-function-test-baseline.md"; do
  require_file "$path"
done

if ! grep -Fxq "20" "$ROOT_DIR/.nvmrc"; then
  printf '%s\n' ".nvmrc must pin the Node 20 baseline required by twilio-run 5.x." >&2
  exit 1
fi

if ! grep -Fq '"node": "20"' "$PACKAGE_JSON"; then
  printf '%s\n' "package.json engines must pin Node 20." >&2
  exit 1
fi

if ! grep -Fq '"twilio-run": "^5.0.1"' "$PACKAGE_JSON"; then
  printf '%s\n' "package.json must keep the twilio-run 5.x baseline." >&2
  exit 1
fi

if ! grep -Fq '"twilio-run": "^5.0.1"' "$PACKAGE_LOCK"; then
  printf '%s\n' "package-lock.json must match the twilio-run package baseline." >&2
  exit 1
fi

if ! grep -Fq '"test": "node scripts/test-functions.js"' "$PACKAGE_JSON"; then
  printf '%s\n' "package.json must expose the function test script." >&2
  exit 1
fi

if ! grep -Fq '"verify": "npm test && npm run check && npm run audit"' "$PACKAGE_JSON"; then
  printf '%s\n' "package.json must expose the combined verify script." >&2
  exit 1
fi

if ! grep -Fq '"audit": "npm audit --audit-level=high"' "$PACKAGE_JSON"; then
  printf '%s\n' "package.json must expose the high-severity audit script." >&2
  exit 1
fi

if ! grep -Fq "npm run audit" "$README"; then
  printf '%s\n' "README must document the high-severity audit gate." >&2
  exit 1
fi

if ! grep -Fq '"title": "^4.0.1"' "$PACKAGE_JSON"; then
  printf '%s\n' "package.json must override title to the patched 4.x baseline." >&2
  exit 1
fi

if ! grep -Fq '"file-type": "^21.3.4"' "$PACKAGE_JSON"; then
  printf '%s\n' "package.json must override file-type to the patched Node 20 baseline." >&2
  exit 1
fi

if ! grep -Fq "Twilio function tests passed." "$ROOT_DIR/scripts/test-functions.js"; then
  printf '%s\n' "Function tests must have a clear success marker." >&2
  exit 1
fi

if ! grep -Fq "Private message asset /message.js is not available." "$ROOT_DIR/functions/private-message.js"; then
  printf '%s\n' "private-message must report a missing private asset through callback(error)." >&2
  exit 1
fi

if grep -Fq "TWILIO_ACCOUNT_SID" "$WORKFLOW" && ! grep -Fq "github.event_name == 'workflow_dispatch'" "$WORKFLOW"; then
  printf '%s\n' "Credentialed deploy steps must be gated to manual workflow_dispatch runs." >&2
  exit 1
fi

if ! grep -Fq "npm run verify" "$WORKFLOW"; then
  printf '%s\n' "Workflow must run the local verification script." >&2
  exit 1
fi

if ! grep -Fq "actions/checkout@v4" "$WORKFLOW"; then
  printf '%s\n' "Workflow must use the current checkout action baseline." >&2
  exit 1
fi

if ! grep -Fq "actions/setup-node@v4" "$WORKFLOW"; then
  printf '%s\n' "Workflow must use the current setup-node action baseline." >&2
  exit 1
fi

if ! grep -Fq "node-version-file: .nvmrc" "$WORKFLOW"; then
  printf '%s\n' "Workflow must read Node version from .nvmrc." >&2
  exit 1
fi

if ! grep -Fq "npm run verify" "$README"; then
  printf '%s\n' "README must document the verification command." >&2
  exit 1
fi

if ! grep -Fq "workflow_dispatch" "$README"; then
  printf '%s\n' "README must document manual deployment workflow behavior." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$PLAN"; then
  printf '%s\n' "Plan must be marked completed." >&2
  exit 1
fi

printf '%s\n' "continuous-cli-101 Twilio baseline checks passed."
