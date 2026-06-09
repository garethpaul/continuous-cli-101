#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PACKAGE_JSON="$ROOT_DIR/package.json"
PACKAGE_LOCK="$ROOT_DIR/package-lock.json"
WORKFLOW="$ROOT_DIR/.github/workflows/main.yml"
README="$ROOT_DIR/README.md"
PLAN="$ROOT_DIR/docs/plans/2026-06-08-twilio-function-test-baseline.md"
LINT_PLAN="$ROOT_DIR/docs/plans/2026-06-08-eslint-quality-gate.md"
PRIVATE_ASSET_PATH_PLAN="$ROOT_DIR/docs/plans/2026-06-09-private-asset-path-guard.md"
PRIVATE_ASSET_ABSOLUTE_PATH_PLAN="$ROOT_DIR/docs/plans/2026-06-09-private-asset-absolute-path-guard.md"
README_CONTRACT_WHITESPACE_PLAN="$ROOT_DIR/docs/plans/2026-06-09-readme-contract-whitespace-guard.md"

require_file() {
  path=$1
  if [ ! -f "$ROOT_DIR/$path" ]; then
    printf '%s\n' "Required file is missing: $path" >&2
    exit 1
  fi
}

for path in \
  ".nvmrc" \
  "eslint.config.js" \
  "README.md" \
  "package.json" \
  "package-lock.json" \
  ".github/workflows/main.yml" \
  "CHANGES.md" \
  "assets/message.private.js" \
  "functions/hello-world.js" \
  "functions/private-message.js" \
  "functions/sms/reply.protected.js" \
  "scripts/fixtures/blank-message.js" \
  "scripts/fixtures/non-function-message.js" \
  "scripts/test-functions.js" \
  "docs/plans/2026-06-08-twilio-function-test-baseline.md" \
  "docs/plans/2026-06-08-eslint-quality-gate.md" \
  "docs/plans/2026-06-09-private-asset-export-guard.md" \
  "docs/plans/2026-06-09-private-asset-path-guard.md" \
  "docs/plans/2026-06-09-private-asset-absolute-path-guard.md" \
  "docs/plans/2026-06-09-readme-contract-whitespace-guard.md" \
  "docs/plans/2026-06-09-twiml-harness-escaping.md"; do
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

if ! grep -Fq '"eslint": "^9.' "$PACKAGE_JSON"; then
  printf '%s\n' "package.json must keep the ESLint 9.x lint baseline." >&2
  exit 1
fi

if ! grep -Fq '"test": "node scripts/test-functions.js"' "$PACKAGE_JSON"; then
  printf '%s\n' "package.json must expose the function test script." >&2
  exit 1
fi

if ! grep -Fq '"lint": "eslint assets functions scripts --max-warnings=0"' "$PACKAGE_JSON"; then
  printf '%s\n' "package.json must expose the JavaScript lint script." >&2
  exit 1
fi

if ! grep -Fq '"verify": "npm run lint && npm test && npm run check && npm run audit"' "$PACKAGE_JSON"; then
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

if ! grep -Fq "npm run lint" "$README"; then
  printf '%s\n' "README must document the JavaScript lint gate." >&2
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

if ! grep -Fq "function escapeXml" "$ROOT_DIR/scripts/test-functions.js"; then
  printf '%s\n' "Function tests must escape local TwiML message bodies." >&2
  exit 1
fi

if ! grep -Fq "&amp;" "$ROOT_DIR/scripts/test-functions.js" ||
  ! grep -Fq "&lt;" "$ROOT_DIR/scripts/test-functions.js" ||
  ! grep -Fq "&quot;" "$ROOT_DIR/scripts/test-functions.js" ||
  ! grep -Fq "&apos;" "$ROOT_DIR/scripts/test-functions.js"; then
  printf '%s\n' "Function tests must cover XML entity escaping in TwiML output." >&2
  exit 1
fi

if ! grep -Fq 'Runtime: "readonly"' "$ROOT_DIR/eslint.config.js"; then
  printf '%s\n' "ESLint config must recognize Twilio Runtime globals." >&2
  exit 1
fi

if ! grep -Fq 'Twilio: "readonly"' "$ROOT_DIR/eslint.config.js"; then
  printf '%s\n' "ESLint config must recognize Twilio helper globals." >&2
  exit 1
fi

if ! grep -Fq "Private message asset /message.js is not available." "$ROOT_DIR/functions/private-message.js"; then
  printf '%s\n' "private-message must report a missing private asset through callback(error)." >&2
  exit 1
fi

if ! grep -Fq "const path = require('path');" "$ROOT_DIR/functions/private-message.js"; then
  printf '%s\n' "private-message must use Node path helpers for asset path validation." >&2
  exit 1
fi

if ! grep -Fq "assets && assets['/message.js']" "$ROOT_DIR/functions/private-message.js"; then
  printf '%s\n' "private-message must guard a missing Runtime asset map before reading /message.js." >&2
  exit 1
fi

if ! grep -Fq "typeof privateMessageAsset.path !== 'string'" "$ROOT_DIR/functions/private-message.js" ||
  ! grep -Fq "privateMessageAsset.path.trim() === ''" "$ROOT_DIR/functions/private-message.js"; then
  printf '%s\n' "private-message must reject missing, non-string, or blank private asset paths." >&2
  exit 1
fi

if ! grep -Fq "!path.isAbsolute(privateMessageAsset.path)" "$ROOT_DIR/functions/private-message.js"; then
  printf '%s\n' "private-message must reject non-absolute private asset paths before require()." >&2
  exit 1
fi

if ! grep -Fq "typeof privateMessage !== 'function'" "$ROOT_DIR/functions/private-message.js"; then
  printf '%s\n' "private-message must validate that the private asset exports a function." >&2
  exit 1
fi

if ! grep -Fq "Private message asset /message.js must export a function." "$ROOT_DIR/functions/private-message.js"; then
  printf '%s\n' "private-message must return an explicit malformed private asset error." >&2
  exit 1
fi

if ! grep -Fq "typeof message !== 'string'" "$ROOT_DIR/functions/private-message.js" ||
  ! grep -Fq "message.trim() === ''" "$ROOT_DIR/functions/private-message.js"; then
  printf '%s\n' "private-message must reject blank or non-string private asset output." >&2
  exit 1
fi

if ! grep -Fq "Private message asset /message.js must return a non-empty string." "$ROOT_DIR/functions/private-message.js"; then
  printf '%s\n' "private-message must return an explicit blank private asset message error." >&2
  exit 1
fi

if ! grep -Fq "assets: null" "$ROOT_DIR/scripts/test-functions.js"; then
  printf '%s\n' "Function tests must cover a null Runtime asset map." >&2
  exit 1
fi

if ! grep -Fq 'path: "   "' "$ROOT_DIR/scripts/test-functions.js"; then
  printf '%s\n' "Function tests must cover blank private asset paths." >&2
  exit 1
fi

if ! grep -Fq 'path: "assets/message.private.js"' "$ROOT_DIR/scripts/test-functions.js"; then
  printf '%s\n' "Function tests must cover relative private asset paths." >&2
  exit 1
fi

if ! grep -Fq "non-function-message.js" "$ROOT_DIR/scripts/test-functions.js"; then
  printf '%s\n' "Function tests must cover malformed private asset exports." >&2
  exit 1
fi

if ! grep -Fq "must export a function" "$ROOT_DIR/scripts/test-functions.js"; then
  printf '%s\n' "Function tests must assert the malformed private asset error." >&2
  exit 1
fi

if ! grep -Fq "blank-message.js" "$ROOT_DIR/scripts/test-functions.js" ||
  ! grep -Fq "must return a non-empty string" "$ROOT_DIR/scripts/test-functions.js"; then
  printf '%s\n' "Function tests must cover blank private asset message output." >&2
  exit 1
fi

if grep -Fq "TWILIO_ACCOUNT_SID" "$WORKFLOW" && ! grep -Fq "github.event_name == 'workflow_dispatch'" "$WORKFLOW"; then
  printf '%s\n' "Credentialed deploy steps must be gated to manual workflow_dispatch runs." >&2
  exit 1
fi

if grep -Fq "npm install --global twilio-cli" "$WORKFLOW" || grep -Fq "twilio plugins:install" "$WORKFLOW"; then
  printf '%s\n' "Workflow deploy must use the package-lock-pinned twilio-run script instead of global Twilio CLI installs." >&2
  exit 1
fi

if ! grep -Fq "npm run deploy -- --service-name=example-deployed-with-github-actions --environment=dev --force" "$WORKFLOW"; then
  printf '%s\n' "Workflow deploy must call the package-lock-pinned npm deploy script." >&2
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

README_TEXT=$(tr '\n' ' ' < "$README")

readme_has() {
  printf '%s\n' "$README_TEXT" | grep -Fq "$1"
}

if ! readme_has "npm run verify"; then
  printf '%s\n' "README must document the verification command." >&2
  exit 1
fi

if ! readme_has "null Runtime asset map"; then
  printf '%s\n' "README must document the null Runtime asset-map test case." >&2
  exit 1
fi

if ! readme_has "blank private asset path"; then
  printf '%s\n' "README must document blank private asset path coverage." >&2
  exit 1
fi

if ! readme_has "relative private asset path"; then
  printf '%s\n' "README must document relative private asset path coverage." >&2
  exit 1
fi

if ! readme_has "malformed private asset export"; then
  printf '%s\n' "README must document malformed private asset export coverage." >&2
  exit 1
fi

if ! readme_has "blank private asset message"; then
  printf '%s\n' "README must document blank private asset message coverage." >&2
  exit 1
fi

if ! readme_has "XML-escapes local TwiML message"; then
  printf '%s\n' "README must document local TwiML escaping coverage." >&2
  exit 1
fi

if ! grep -Fq "workflow_dispatch" "$README"; then
  printf '%s\n' "README must document manual deployment workflow behavior." >&2
  exit 1
fi

if ! grep -Fq "package-lock-pinned deploy script" "$README"; then
  printf '%s\n' "README must document the locked deploy script baseline." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$PLAN"; then
  printf '%s\n' "Plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$LINT_PLAN"; then
  printf '%s\n' "Lint plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-09-private-asset-export-guard.md"; then
  printf '%s\n' "Private asset export guard plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-private-asset-export-guard.md"; then
  printf '%s\n' "Private asset export guard plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$PRIVATE_ASSET_PATH_PLAN"; then
  printf '%s\n' "Private asset path guard plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$PRIVATE_ASSET_PATH_PLAN"; then
  printf '%s\n' "Private asset path guard plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$PRIVATE_ASSET_ABSOLUTE_PATH_PLAN"; then
  printf '%s\n' "Private asset absolute path guard plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$PRIVATE_ASSET_ABSOLUTE_PATH_PLAN"; then
  printf '%s\n' "Private asset absolute path guard plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$README_CONTRACT_WHITESPACE_PLAN"; then
  printf '%s\n' "README contract whitespace guard plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$README_CONTRACT_WHITESPACE_PLAN"; then
  printf '%s\n' "README contract whitespace guard plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-09-locked-twilio-deploy-script.md"; then
  printf '%s\n' "Locked Twilio deploy script plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-locked-twilio-deploy-script.md"; then
  printf '%s\n' "Locked Twilio deploy script plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-09-twiml-harness-escaping.md"; then
  printf '%s\n' "TwiML harness escaping plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-twiml-harness-escaping.md"; then
  printf '%s\n' "TwiML harness escaping plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-09-private-asset-message-text-guard.md"; then
  printf '%s\n' "Private asset message text guard plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-private-asset-message-text-guard.md"; then
  printf '%s\n' "Private asset message text guard plan must record make check verification." >&2
  exit 1
fi

printf '%s\n' "continuous-cli-101 Twilio baseline checks passed."
