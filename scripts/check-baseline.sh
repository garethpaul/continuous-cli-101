#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
CALLBACK_TEST="$ROOT_DIR/scripts/test-functions.js"
DUPLICATE_CALLBACK_PLAN="$ROOT_DIR/docs/plans/2026-06-13-twilio-duplicate-callback-detection.md"
PACKAGE_JSON="$ROOT_DIR/package.json"
PACKAGE_LOCK="$ROOT_DIR/package-lock.json"
WORKFLOW="$ROOT_DIR/.github/workflows/main.yml"
README="$ROOT_DIR/README.md"
PLAN="$ROOT_DIR/docs/plans/2026-06-08-twilio-function-test-baseline.md"
LINT_PLAN="$ROOT_DIR/docs/plans/2026-06-08-eslint-quality-gate.md"
PRIVATE_ASSET_PATH_PLAN="$ROOT_DIR/docs/plans/2026-06-09-private-asset-path-guard.md"
PRIVATE_ASSET_ABSOLUTE_PATH_PLAN="$ROOT_DIR/docs/plans/2026-06-09-private-asset-absolute-path-guard.md"
README_CONTRACT_WHITESPACE_PLAN="$ROOT_DIR/docs/plans/2026-06-09-readme-contract-whitespace-guard.md"
PRIVATE_ASSET_FILE_PATH_PLAN="$ROOT_DIR/docs/plans/2026-06-09-private-asset-file-path-guard.md"
TWIML_RESPONSE_ENVELOPE_PLAN="$ROOT_DIR/docs/plans/2026-06-09-twiml-response-envelope.md"
DEPLOYMENT_SAFETY_PLAN="$ROOT_DIR/docs/plans/2026-06-10-twilio-deployment-safety.md"
DEPLOYMENT_REF_PLAN="$ROOT_DIR/docs/plans/2026-06-10-twilio-main-branch-deploy-guard.md"
SINGLE_COMPLETION_PLAN="$ROOT_DIR/docs/plans/2026-06-12-private-message-single-completion.md"
CODEQL_PLAN="$ROOT_DIR/docs/plans/2026-06-12-codeql-baseline.md"
CALLBACK_TIMEOUT_PLAN="$ROOT_DIR/docs/plans/2026-06-13-twilio-callback-timeout-harness.md"
ESLINT_UPGRADE_PLAN="$ROOT_DIR/docs/plans/2026-06-13-eslint-10-5-upgrade.md"
MAKE_ROOT_PROTECTION_PLAN="$ROOT_DIR/docs/plans/2026-06-14-make-root-override-protection.md"
CONCURRENT_HARNESS_PLAN="$ROOT_DIR/docs/plans/2026-06-15-twilio-concurrent-harness-isolation.md"
FORM_DATA_PLAN="$ROOT_DIR/docs/plans/2026-06-15-form-data-crlf-remediation.md"
ALL_BRANCH_VERIFICATION_PLAN="$ROOT_DIR/docs/plans/2026-06-17-continuous-cli-all-branch-verification.md"
EXPECTED_WORKFLOW=$(mktemp "${TMPDIR:-/tmp}/continuous-cli-workflow.XXXXXX")
trap 'rm -f "$EXPECTED_WORKFLOW"' EXIT HUP INT TERM

if ! git -C "$ROOT_DIR" rev-parse --verify 'HEAD^{tree}' >/dev/null 2>&1; then
  printf '%s\n' "Baseline integrity requires the current HEAD tree and Git index." >&2
  exit 1
fi

if [ "${CONTINUOUS_CLI_SHALLOW_BASELINE_ACTIVE:-}" = 1 ] && \
   ! git -C "$ROOT_DIR" diff --quiet --no-ext-diff HEAD -- \
    Makefile \
    scripts/check-baseline.sh \
    scripts/run-with-timeout.js \
    scripts/test-baseline-working-tree-contract.sh \
    scripts/test-run-with-timeout.js \
    scripts/check-descriptor-discovery-bundle.js \
    scripts/check-descriptor-discovery-lint-contract.js \
    scripts/check-descriptor-discovery-test-wiring.js \
    scripts/copy-tracked-worktree.sh \
    scripts/descriptor-discovery.js \
    scripts/test-descriptor-discovery.js \
    scripts/test-make-path-boundary.sh \
    scripts/test-make-version-routing.sh \
    scripts/test-make-path-boundary-v3-red.sh \
    scripts/test-make-path-boundary-v4.sh \
    scripts/test-make-high-fd.sh \
    scripts/test-make-descriptor-types.sh \
    scripts/test-make-proc-simulation.sh \
    scripts/test-make-lsof-output.sh \
    scripts/test-make-proc-large-output.sh \
    scripts/test-make-lsof-truncation.sh \
    scripts/test-make-linux-authority-mutations.sh \
    scripts/test-make-path-boundary-mutations.sh \
    scripts/test-shallow-baseline.sh \
    scripts/test-shallow-baseline-mutation.sh \
    scripts/test-copy-tracked-worktree.sh \
    scripts/test-copy-tar-portability.sh \
    scripts/test-copy-tar-portability-mutation.sh; then
  printf '%s\n' "Critical verifier files must match the current HEAD tree." >&2
  exit 1
fi

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
  "SECURITY.md" \
  "VISION.md" \
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
  ".continuous-cli-root" \
  "scripts/check-descriptor-discovery-bundle.js" \
  "scripts/check-descriptor-discovery-lint-contract.js" \
  "scripts/check-descriptor-discovery-test-wiring.js" \
  "scripts/run-with-timeout.js" \
  "scripts/test-baseline-working-tree-contract.sh" \
  "scripts/descriptor-discovery.js" \
  "scripts/test-descriptor-discovery.js" \
  "scripts/test-make-path-boundary.sh" \
  "scripts/test-make-version-routing.sh" \
  "scripts/test-make-path-boundary-v3-red.sh" \
  "scripts/test-make-path-boundary-v4.sh" \
  "scripts/test-make-high-fd.sh" \
  "scripts/test-make-descriptor-types.sh" \
  "scripts/test-make-proc-simulation.sh" \
  "scripts/test-make-lsof-output.sh" \
  "scripts/test-make-proc-large-output.sh" \
  "scripts/test-make-lsof-truncation.sh" \
  "scripts/test-make-linux-authority-mutations.sh" \
  "scripts/test-make-path-boundary-mutations.sh" \
  "scripts/copy-tracked-worktree.sh" \
  "scripts/test-shallow-baseline.sh" \
  "scripts/test-shallow-baseline-mutation.sh" \
  "scripts/test-copy-tracked-worktree.sh" \
  "scripts/test-copy-tar-portability.sh" \
  "scripts/test-copy-tar-portability-mutation.sh" \
  "scripts/test-run-with-timeout.js" \
  "scripts/test-functions.js" \
  "docs/plans/2026-06-08-twilio-function-test-baseline.md" \
  "docs/plans/2026-06-08-eslint-quality-gate.md" \
  "docs/plans/2026-06-09-private-asset-export-guard.md" \
  "docs/plans/2026-06-09-private-asset-path-guard.md" \
  "docs/plans/2026-06-09-private-asset-absolute-path-guard.md" \
  "docs/plans/2026-06-09-private-asset-file-path-guard.md" \
  "docs/plans/2026-06-09-readme-contract-whitespace-guard.md" \
  "docs/plans/2026-06-09-twiml-harness-escaping.md" \
  "docs/plans/2026-06-09-twiml-response-envelope.md" \
  "docs/plans/2026-06-10-twilio-deployment-safety.md"; do
  require_file "$path"
done

require_file "docs/plans/2026-06-10-twilio-main-branch-deploy-guard.md"
require_file "docs/plans/2026-06-12-private-message-single-completion.md"
require_file "docs/plans/2026-06-12-codeql-baseline.md"
require_file "docs/plans/2026-06-13-twilio-callback-timeout-harness.md"
require_file "docs/plans/2026-06-13-eslint-10-5-upgrade.md"
require_file "docs/plans/2026-06-14-make-root-override-protection.md"
require_file "docs/plans/2026-06-15-twilio-concurrent-harness-isolation.md"
require_file "docs/plans/2026-06-15-form-data-crlf-remediation.md"
require_file "docs/plans/2026-06-17-continuous-cli-all-branch-verification.md"

if ! grep -Fq 'CONTINUOUS_CLI_ROOT_ID :=' "$ROOT_DIR/Makefile" || \
   ! grep -Fq 'ifeq ($(MAKE_VERSION),3.81)' "$ROOT_DIR/Makefile" || \
   ! grep -Fq 'else ifeq ($(MAKE_VERSION),3.82)' "$ROOT_DIR/Makefile" || \
   ! grep -Fq 'CONTINUOUS_CLI_MAKEFILE_LIST = $(value MAKEFILE_LIST)' "$ROOT_DIR/Makefile" || \
   ! grep -Fq 'export CONTINUOUS_CLI_MAKEFILE_LIST' "$ROOT_DIR/Makefile" || \
   ! grep -Fq 'discoverFromMakefileList' "$ROOT_DIR/scripts/descriptor-discovery.js" || \
   ! grep -Fq 'CONTINUOUS_CLI_DISCOVERY_MODULE :=' "$ROOT_DIR/Makefile" || \
   ! grep -Fq '$(CONTINUOUS_CLI_DISCOVERY_MODULE) auto $$$$' "$ROOT_DIR/Makefile" || \
   ! grep -Fq 'CONTINUOUS_CLI_LSOF_END :=' "$ROOT_DIR/Makefile" || \
   ! grep -Fq 'fs.constants.O_NONBLOCK' "$ROOT_DIR/scripts/descriptor-discovery.js" || \
   ! grep -Fq 'fs.fstatSync(handle).isFile()' "$ROOT_DIR/scripts/descriptor-discovery.js" || \
   ! grep -Fq 'const READ_LIMIT = 65536' "$ROOT_DIR/scripts/descriptor-discovery.js" || \
   ! grep -Fq 'const FIELD_LIMIT = 65536' "$ROOT_DIR/scripts/descriptor-discovery.js" || \
   ! grep -Fq "childProcess.spawn('lsof'" "$ROOT_DIR/scripts/descriptor-discovery.js" || \
   ! grep -Fq '$(file >$(CONTINUOUS_CLI_PARSE_FILE),$(value MAKEFILE_LIST)$(CONTINUOUS_CLI_LIST_END))' "$ROOT_DIR/Makefile" || \
   ! grep -Fq '[ "$$count" -eq 1 ]' "$ROOT_DIR/Makefile" || \
   ! grep -Fq 'root_b64=$$(printf %s "$$PWD/." | base64' "$ROOT_DIR/Makefile" || \
   ! grep -Fq 'exec "$$NPM" --prefix "$$PWD"' "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile verification must use the exact parse-time identity channel and physical root." >&2
  exit 1
fi

if grep -Fq 'export CONTINUOUS_CLI_PARSE_LIST' "$ROOT_DIR/Makefile" || \
   grep -Fq 'CONTINUOUS_CLI_MAKEFILE_MARKER := continuous-cli-101' "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile identity must not export MAKEFILE_LIST or use a public marker scan." >&2
  exit 1
fi

if ! grep -Fxq '8f5148870e1d4b44b928c54e3e730882' "$ROOT_DIR/.continuous-cli-root" || \
   ! grep -Fq 'dollar-directory' "$ROOT_DIR/scripts/test-make-path-boundary-v4.sh" || \
   ! grep -Fq 'dollar-makefile' "$ROOT_DIR/scripts/test-make-path-boundary-v4.sh" || \
   ! grep -Fq 'multi-collision' "$ROOT_DIR/scripts/test-make-path-boundary-v4.sh" || \
   ! grep -Fq 'include-collision' "$ROOT_DIR/scripts/test-make-path-boundary-v4.sh" || \
   ! grep -Fq 'duplicate-identity' "$ROOT_DIR/scripts/test-make-path-boundary-v4.sh" || \
   ! grep -Fq 'INHERITED_FD_COUNT' "$ROOT_DIR/scripts/test-make-high-fd.sh" || \
   ! grep -Fq "descriptor_type == 'fifo'" "$ROOT_DIR/scripts/test-make-descriptor-types.sh" || \
   ! grep -Fq 'DESCRIPTOR_GENERATOR' "$ROOT_DIR/scripts/test-make-proc-simulation.sh" || \
   grep -Fq 'jot ' "$ROOT_DIR/scripts/test-make-proc-simulation.sh" || \
   ! grep -Fq 'INHERITED_REGULAR_FD_COUNT' "$ROOT_DIR/scripts/test-make-lsof-output.sh" || \
   ! grep -Fq 'INHERITED_REGULAR_FD_COUNT' "$ROOT_DIR/scripts/test-make-proc-large-output.sh" || \
   ! grep -Fq 'test-descriptor-discovery.js' "$ROOT_DIR/scripts/test-make-lsof-truncation.sh" || \
   ! grep -Fq "'truncated record'" "$ROOT_DIR/scripts/test-descriptor-discovery.js" || \
   ! grep -Fq "'nonzero child'" "$ROOT_DIR/scripts/test-descriptor-discovery.js" || \
   ! grep -Fq "'post-sentinel framing'" "$ROOT_DIR/scripts/test-descriptor-discovery.js" || \
   ! grep -Fq 'generator-failure-suppressed' "$ROOT_DIR/scripts/test-make-linux-authority-mutations.sh" || \
   ! grep -Fq 'direct-parser-framing-bypassed' "$ROOT_DIR/scripts/test-make-linux-authority-mutations.sh" || \
   ! grep -Fq 'direct-helper-test-bypassed' "$ROOT_DIR/scripts/test-make-linux-authority-mutations.sh" || \
   ! grep -Fq 'make-381-list-export' "$ROOT_DIR/scripts/test-make-path-boundary-mutations.sh" || \
   ! grep -Fq 'fixed-lsof-descriptor-range' "$ROOT_DIR/scripts/test-make-path-boundary-mutations.sh" || \
   ! grep -Fq 'fifo-socket-regular-filter-removed' "$ROOT_DIR/scripts/test-make-path-boundary-mutations.sh" || \
   ! grep -Fq 'lsof-output-truncated' "$ROOT_DIR/scripts/test-make-path-boundary-mutations.sh" || \
   ! grep -Fq 'git -C "$ROOT_DIR" ls-files -z' "$ROOT_DIR/scripts/copy-tracked-worktree.sh" || \
   grep -Fq 'archive 1c82b9674e7bc39a6722e2617b90a3c55e0de026' "$ROOT_DIR/scripts/copy-tracked-worktree.sh" || \
   ! grep -Fq 'single-commit fixture unexpectedly contains the original parent tree' "$ROOT_DIR/scripts/test-shallow-baseline.sh" || \
   ! grep -Fq 'shallow-parent-tree-dependence' "$ROOT_DIR/scripts/test-shallow-baseline-mutation.sh" || \
   ! grep -Fq 'public-marker-scan' "$ROOT_DIR/scripts/test-make-path-boundary-mutations.sh"; then
  printf '%s\n' "Makefile path tests must preserve exact package identity and blocker mutations." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$MAKE_ROOT_PROTECTION_PLAN" || \
   ! grep -Fq "## Status: Completed" "$MAKE_ROOT_PROTECTION_PLAN" || \
   ! grep -Fq 'make ROOT=/tmp check' "$MAKE_ROOT_PROTECTION_PLAN" || \
   ! grep -Fq "four Make gates" "$MAKE_ROOT_PROTECTION_PLAN" || \
   ! grep -Fq "external working directory" "$MAKE_ROOT_PROTECTION_PLAN" || \
   ! grep -Fq "Four isolated hostile mutations were rejected" "$MAKE_ROOT_PROTECTION_PLAN"; then
  printf '%s\n' "Make root protection plan must record completed hostile-override and external verification." >&2
  exit 1
fi

if ! grep -Fxq "22" "$ROOT_DIR/.nvmrc"; then
  printf '%s\n' ".nvmrc must pin the supported Node 22 baseline for twilio-run 5.x." >&2
  exit 1
fi

if ! grep -Fq '"node": "^22.13.0"' "$PACKAGE_JSON"; then
  printf '%s\n' "package.json engines must require the supported Node 22 baseline." >&2
  exit 1
fi

if ! grep -Fq '"twilio-run": "5.0.1"' "$PACKAGE_JSON"; then
  printf '%s\n' "package.json must keep the twilio-run 5.x baseline." >&2
  exit 1
fi

if ! grep -Fq '"twilio-run": "5.0.1"' "$PACKAGE_LOCK"; then
  printf '%s\n' "package-lock.json must match the twilio-run package baseline." >&2
  exit 1
fi

if ! grep -Fq '"eslint": "10.5.0"' "$PACKAGE_JSON"; then
  printf '%s\n' "package.json must keep the ESLint 10.5.0 lint baseline." >&2
  exit 1
fi

if ! node -e '
  const fs = require("node:fs");
  const lock = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const rootVersion = lock.packages?.[""]?.devDependencies?.eslint;
  const eslintPackage = lock.packages?.["node_modules/eslint"];
  const legacyPackage = lock.dependencies?.eslint;
  const expected = {
    version: "10.5.0",
    resolved: "https://registry.npmjs.org/eslint/-/eslint-10.5.0.tgz",
    integrity: "sha512-1y+7C+vi12bUK1IpZeaV3gsH9fHLBmPvYmPx42pvT/E9yG0IC8g3PUZZgp0+JLJl7ZDK0flc2gc+Aw9dpCvIsQ==",
  };
  if (rootVersion !== expected.version) process.exit(1);
  for (const entry of [eslintPackage, legacyPackage]) {
    if (!entry || Object.keys(expected).some((key) => entry[key] !== expected[key])) process.exit(1);
  }
' "$PACKAGE_LOCK"; then
  printf '%s\n' "package-lock.json must pin the verified ESLint 10.5.0 artifact." >&2
  exit 1
fi

if ! node -e '
  const fs = require("node:fs");
  const lock = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const expected = new Map([
    ["node_modules/form-data", [2, 5, 6]],
    ["node_modules/axios/node_modules/form-data", [4, 0, 6]],
  ]);
  function atLeast(version, minimum) {
    const parts = version.split(".").map(Number);
    if (parts.length !== 3 || parts.some(Number.isNaN) || parts[0] !== minimum[0]) return false;
    return parts.some((part, index) =>
      part > minimum[index] && parts.slice(0, index).every((value, prior) => value === minimum[prior])
    ) || parts.every((part, index) => part === minimum[index]);
  }
  for (const [path, minimum] of expected) {
    const entry = lock.packages?.[path];
    if (!entry || typeof entry.version !== "string" || !atLeast(entry.version, minimum)) process.exit(1);
  }
' "$PACKAGE_LOCK"; then
  printf '%s\n' "package-lock.json must keep both form-data dependency lines on CRLF-safe releases." >&2
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

if ! grep -Fq '"audit": "npm audit --audit-level=moderate"' "$PACKAGE_JSON"; then
  printf '%s\n' "package.json must expose the moderate-severity audit script." >&2
  exit 1
fi

if ! grep -Fq 'ESLint `10.5.0` under Node 22' "$README" ||
   ! grep -Fq 'docs/plans/2026-06-13-eslint-10-5-upgrade.md' "$README"; then
  printf '%s\n' "README must document the verified ESLint 10.5.0 maintenance baseline." >&2
  exit 1
fi

if ! grep -Fq 'ESLint 10.4.1 to 10.5.0' "$ROOT_DIR/CHANGES.md"; then
  printf '%s\n' "CHANGES.md must record the ESLint 10.5.0 upgrade." >&2
  exit 1
fi

if ! grep -Fq 'Keep the ESLint release exact, current, and verified' "$ROOT_DIR/VISION.md"; then
  printf '%s\n' "VISION.md must preserve the exact ESLint maintenance priority." >&2
  exit 1
fi

for plan_contract in \
  'status: completed' \
  '## Status: Completed' \
  '## Work Completed' \
  '## Verification Completed' \
  'Node `22.22.2` `npm ci --ignore-scripts`' \
  '`npm outdated --json` returned `{}`'; do
  if ! grep -Fq "$plan_contract" "$ESLINT_UPGRADE_PLAN"; then
    printf '%s\n' "ESLint upgrade plan must keep completed evidence: $plan_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "npm run audit" "$README"; then
  printf '%s\n' "README must document the moderate-severity audit gate." >&2
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

for timeout_contract in \
  'const {clearTimeout, setTimeout} = require("node:timers");' \
  'const DEFAULT_CALLBACK_TIMEOUT_MS = 5000;' \
  'let settled = false;' \
  'function settle(operation)' \
  'if (settled)' \
  'settled = true;' \
  'clearTimeout(timeoutId);' \
  'timeoutId = setTimeout(function handleCallbackTimeout()' \
  'settle(function completeCallback()' \
  'settle(function rejectSynchronousFailure()'; do
  if ! grep -Fq "$timeout_contract" "$ROOT_DIR/scripts/test-functions.js"; then
    printf '%s\n' "Function harness must keep callback timeout contract: $timeout_contract" >&2
    exit 1
  fi
done

if [ "$(grep -Fc 'Twilio handler did not invoke its callback within ' "$ROOT_DIR/scripts/test-functions.js")" -ne 3 ] || \
   ! grep -Fq 'function neverCallsBack() {}' "$ROOT_DIR/scripts/test-functions.js" || \
   ! grep -Fq '{timeoutMs: 10}' "$ROOT_DIR/scripts/test-functions.js" || \
   ! grep -Fq 'function captureLateCallback(context, event, callback)' "$ROOT_DIR/scripts/test-functions.js" || \
   ! grep -Fq 'function throwSynchronously()' "$ROOT_DIR/scripts/test-functions.js"; then
  printf '%s\n' "Function tests must execute missing, late, and synchronous callback completion boundaries." >&2
  exit 1
fi

for async_handler_contract in \
  'const handlerResult = handler(' \
  'Promise.resolve(handlerResult).catch(function rejectReturnedPromise(error)' \
  'function rejectWithoutCallback()' \
  'Async handler rejection must not wait for the callback timeout.' \
  'function callbackThenReject(context, event, callback)' \
  'Post-callback rejection sentinel.'; do
  if ! grep -Fq "$async_handler_contract" "$CALLBACK_TEST"; then
    printf '%s\n' "Function harness must preserve async handler failure contract: $async_handler_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "bounded callback deadline" "$README" || \
   ! grep -Fq "time-bounded Twilio callback verification" "$ROOT_DIR/VISION.md" || \
   ! grep -Fq "false-green missing-callback tests" "$ROOT_DIR/CHANGES.md" || \
   ! grep -Fq "R6. The repository contract must enforce" "$CALLBACK_TIMEOUT_PLAN"; then
  printf '%s\n' "Callback timeout harness documentation and plan contracts must remain checked in." >&2
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

if ! grep -Fq "multiMessageResponse" "$ROOT_DIR/scripts/test-functions.js" ||
  ! grep -Fq "<Response><Message>First</Message><Message>Second</Message></Response>" "$ROOT_DIR/scripts/test-functions.js"; then
  printf '%s\n' "Function tests must cover multiple TwiML messages in one response envelope." >&2
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

if [ "$(grep -Fc "callback(error);" "$ROOT_DIR/functions/private-message.js")" -ne 1 ] || \
   [ "$(grep -Fc "callback(null, twiml);" "$ROOT_DIR/functions/private-message.js")" -ne 1 ]; then
  printf '%s\n' "private-message must keep one error and one success completion site." >&2
  exit 1
fi

if [ "$(grep -Fc "throw new Error('Private message asset /message.js" "$ROOT_DIR/functions/private-message.js")" -ne 3 ]; then
  printf '%s\n' "private-message validation failures must flow through the single error completion site." >&2
  exit 1
fi

catch_line=$(grep -Fn "  } catch (error) {" "$ROOT_DIR/functions/private-message.js" | cut -d: -f1)
error_callback_line=$(grep -Fn "    callback(error);" "$ROOT_DIR/functions/private-message.js" | cut -d: -f1)
success_callback_line=$(grep -Fn "  callback(null, twiml);" "$ROOT_DIR/functions/private-message.js" | cut -d: -f1)
error_completion=$(awk '/^  } catch \(error\) \{$/,/^  }$/' "$ROOT_DIR/functions/private-message.js")
expected_error_completion='  } catch (error) {
    callback(error);
    return;
  }'

if [ "$catch_line" -ge "$error_callback_line" ] || [ "$error_callback_line" -ge "$success_callback_line" ] || \
   [ "$error_completion" != "$expected_error_completion" ]; then
  printf '%s\n' "private-message success completion must remain outside the error catch boundary." >&2
  exit 1
fi

if ! grep -Fq "function invokeWithThrowingCallback" "$ROOT_DIR/scripts/test-functions.js" || \
   ! grep -Fq "throwingSuccessCalls.length, 1" "$ROOT_DIR/scripts/test-functions.js" || \
   ! grep -Fq "throwingErrorCalls.length, 1" "$ROOT_DIR/scripts/test-functions.js"; then
  printf '%s\n' "Function tests must prove throwing success and error callbacks complete exactly once." >&2
  exit 1
fi

if ! grep -Fq "function invokeWithRecordingCallback" "$ROOT_DIR/scripts/test-functions.js" || \
   ! grep -Fq "recordingErrorCalls.length, 1" "$ROOT_DIR/scripts/test-functions.js"; then
  printf '%s\n' "Function tests must prove a non-throwing error callback completes exactly once." >&2
  exit 1
fi

if [ ! -f "$DUPLICATE_CALLBACK_PLAN" ] || \
   ! grep -Fq "const CALLBACK_OBSERVATION_MS = 10;" "$CALLBACK_TEST" || \
   ! grep -Fq "let callbackCount = 0;" "$CALLBACK_TEST" || \
   [ "$(grep -Fc "if (settled) {" "$CALLBACK_TEST")" -lt 2 ] || \
   [ "$(grep -Fc "clearTimeout(timeoutId);" "$CALLBACK_TEST")" -lt 2 ] || \
   ! grep -Fq "clearTimeout(callbackObservationId);" "$CALLBACK_TEST" || \
   ! grep -Fq "if (callbackCount > 1)" "$CALLBACK_TEST" || \
   ! grep -Fq "Twilio handler invoked its callback more than once." "$CALLBACK_TEST" || \
   ! grep -Fq "function callbackTwiceImmediately" "$CALLBACK_TEST" || \
   ! grep -Fq "function callbackTwiceAcrossTurns" "$CALLBACK_TEST" || \
   ! grep -Fq "function callbackBeforeShortDeadline" "$CALLBACK_TEST" || \
   ! grep -Fq "immediateDuplicateTwilioSentinel" "$CALLBACK_TEST" || \
   ! grep -Fq "deferredDuplicateRuntimeSentinel" "$CALLBACK_TEST"; then
  printf '%s\n' "Twilio harness must reject immediate duplicate callback completion." >&2
  exit 1
fi

if ! grep -Fq "short bounded observation" "$ROOT_DIR/README.md" || \
   ! grep -Fq "near-immediate duplicate" "$ROOT_DIR/CHANGES.md" || \
   ! grep -Fq "reject immediate duplicate completion callbacks" "$ROOT_DIR/VISION.md" || \
   ! grep -Fq "R6. Tests, static contracts" "$DUPLICATE_CALLBACK_PLAN" || \
   ! grep -Fq "status: completed" "$DUPLICATE_CALLBACK_PLAN" || \
   ! grep -Fq "Eight isolated hostile mutations" "$DUPLICATE_CALLBACK_PLAN"; then
  printf '%s\n' "Duplicate callback documentation and plan contracts must remain checked in." >&2
  exit 1
fi

for harness_queue_contract in \
  "let invocationTail = Promise.resolve();" \
  "function invokeIsolated(handler, options)" \
  "invocationTail.then(function beginIsolatedInvocation()" \
  "function releaseInvocationQueue() {}" \
  "function releaseInvocationQueueAfterFailure() {}" \
  "const concurrentResults = await Promise.all([" \
  'assets: {marker: "first invocation"}' \
  'assets: {marker: "second invocation"}' \
  "readFirstOverlappingRuntime" \
  "readSecondOverlappingRuntime" \
  'assets: {marker: "first overlapping invocation"}' \
  'assets: {marker: "second overlapping invocation"}' \
  'timeoutMs: 1' \
  "const recoveryResults = await Promise.allSettled([" \
  '"queue recovered"'; do
  if ! grep -Fq "$harness_queue_contract" "$CALLBACK_TEST"; then
    printf '%s\n' "Concurrent Twilio harness isolation contract is missing: $harness_queue_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "Concurrent harness invocations are serialized before installing process-global Twilio fixtures." "$README" || \
  ! grep -Fq "Keep concurrent local Twilio invocations isolated from process-global fixtures" "$ROOT_DIR/VISION.md" || \
  ! grep -Fq "Concurrent local Twilio tests serialize ownership of process-global Runtime fixtures." "$ROOT_DIR/SECURITY.md" || \
  ! grep -Fq "Serialized concurrent Twilio harness invocations" "$ROOT_DIR/CHANGES.md"; then
  printf '%s\n' "Concurrent harness isolation guidance must remain checked in." >&2
  exit 1
fi

for concurrent_plan_contract in \
  "Status: Completed" \
  "npm run verify" \
  "hostile concurrency mutations were rejected" \
  "No credentialed Twilio deployment was run"; do
  if ! grep -Fq "$concurrent_plan_contract" "$CONCURRENT_HARNESS_PLAN"; then
    printf '%s\n' "Concurrent harness plan must record completed verification: $concurrent_plan_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "Locked both transitive form-data lines on CRLF-safe releases" "$ROOT_DIR/CHANGES.md" || \
   ! grep -Fq "Keep multipart dependencies on CRLF-safe releases" "$ROOT_DIR/VISION.md"; then
  printf '%s\n' "form-data CRLF remediation guidance must remain checked in." >&2
  exit 1
fi

for form_data_plan_contract in \
  "Status: Completed" \
  "npm run verify" \
  "hostile form-data mutations were rejected" \
  "No credentialed Twilio deployment was run"; do
  if ! grep -Fq "$form_data_plan_contract" "$FORM_DATA_PLAN"; then
    printf '%s\n' "form-data remediation plan must record completed verification: $form_data_plan_contract" >&2
    exit 1
  fi
done

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

if ! grep -Fq "const fs = require('fs');" "$ROOT_DIR/functions/private-message.js" ||
  ! grep -Fq "function isReadableFile(assetPath)" "$ROOT_DIR/functions/private-message.js" ||
  ! grep -Fq "const stats = fs.statSync(assetPath);" "$ROOT_DIR/functions/private-message.js" ||
  ! grep -Fq "stats.isFile()" "$ROOT_DIR/functions/private-message.js" ||
  ! grep -Fq "fs.accessSync(assetPath, fs.constants.R_OK)" "$ROOT_DIR/functions/private-message.js" ||
  ! grep -Fq "!isReadableFile(privateMessageAsset.path)" "$ROOT_DIR/functions/private-message.js"; then
  printf '%s\n' "private-message must reject non-file private asset paths before require()." >&2
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

if ! grep -Fq "directoryAssetPathError" "$ROOT_DIR/scripts/test-functions.js" ||
  ! grep -Fq "path: __dirname" "$ROOT_DIR/scripts/test-functions.js"; then
  printf '%s\n' "Function tests must cover directory private asset paths." >&2
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

for workflow_contract in \
  "permissions:" \
  "contents: read" \
  "timeout-minutes: 10" \
  "timeout-minutes: 15" \
  "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10" \
  "actions/setup-node@48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e" \
  "persist-credentials: false" \
  "confirm_deploy:" \
  'default: "false"' \
  "type: choice" \
  "inputs.confirm_deploy == 'true'" \
  "github.ref == 'refs/heads/main'" \
  "environment: twilio-development" \
  "group: twilio-development" \
  "cancel-in-progress: false"; do
  if ! grep -Fq "$workflow_contract" "$WORKFLOW"; then
    printf '%s\n' "Workflow must keep deployment safety contract: $workflow_contract" >&2
    exit 1
  fi
done

if [ "$(grep -Fc "runs-on: ubuntu-24.04" "$WORKFLOW")" -ne 2 ]; then
  printf '%s\n' "Both workflow jobs must use the stable Ubuntu 24.04 runner image." >&2
  exit 1
fi

if [ "$(grep -Fc "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10" "$WORKFLOW")" -ne 2 ]; then
  printf '%s\n' "Both workflow jobs must use the pinned checkout action." >&2
  exit 1
fi

if [ "$(grep -Fc "actions/setup-node@48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e" "$WORKFLOW")" -ne 2 ]; then
  printf '%s\n' "Both workflow jobs must use the pinned setup-node action." >&2
  exit 1
fi

if [ "$(grep -Fc "persist-credentials: false" "$WORKFLOW")" -ne 2 ]; then
  printf '%s\n' "Both workflow jobs must avoid persisting GitHub credentials." >&2
  exit 1
fi

workflow_trigger_block=$(awk '
  /^on:/ { capture = 1 }
  capture && /^permissions:/ { exit }
  capture { print }
' "$WORKFLOW")
if printf '%s\n' "$workflow_trigger_block" | grep -Eq '^[[:space:]]+branches(-ignore)?:'; then
  printf '%s\n' "Push and pull-request verification must remain unfiltered across branches." >&2
  exit 1
fi

cat > "$EXPECTED_WORKFLOW" <<'EOF'
name: Twilio CI

on:
  push:
  pull_request:
  workflow_dispatch:
    inputs:
      confirm_deploy:
        description: Confirm deployment to the Twilio development environment
        required: true
        default: "false"
        type: choice
        options:
          - "false"
          - "true"

permissions:
  contents: read

jobs:
  verify:
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
        with:
          persist-credentials: false
      - uses: actions/setup-node@48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e # v6.4.0
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - run: npm run verify

  deploy:
    needs: verify
    if: github.event_name == 'workflow_dispatch' && inputs.confirm_deploy == 'true' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-24.04
    timeout-minutes: 15
    environment: twilio-development
    concurrency:
      group: twilio-development
      cancel-in-progress: false
    steps:
      - uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
        with:
          persist-credentials: false
      - uses: actions/setup-node@48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e # v6.4.0
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - name: Deploy Twilio Serverless service
        env:
          TWILIO_ACCOUNT_SID: ${{ secrets.TWILIO_ACCOUNT_SID }}
          TWILIO_API_KEY: ${{ secrets.TWILIO_API_KEY }}
          TWILIO_API_SECRET: ${{ secrets.TWILIO_API_SECRET }}
        run: npm run deploy -- --service-name=example-deployed-with-github-actions --environment=dev --force
EOF

if find "$ROOT_DIR/.github/workflows" -type f \( -name '*codeql*.yml' -o -name '*codeql*.yaml' \) -print -quit | grep -q .; then
  printf '%s\n' "GitHub default CodeQL setup must not be duplicated by an advanced workflow." >&2
  exit 1
fi

workflow_paths=$(find "$ROOT_DIR/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) -print | sort)
expected_workflow_paths="$WORKFLOW"
if [ "$workflow_paths" != "$expected_workflow_paths" ]; then
  printf '%s\n' "Only the canonical Twilio CI workflow is approved." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$CODEQL_PLAN" || \
   ! grep -Fq "make check" "$CODEQL_PLAN" || \
   ! grep -Fq "external working directory" "$CODEQL_PLAN" || \
   ! grep -Fq "hostile mutations rejected" "$CODEQL_PLAN" || \
   ! grep -Fq "default setup" "$CODEQL_PLAN" || \
   ! grep -Fq "advanced CodeQL workflow" "$CODEQL_PLAN"; then
  printf '%s\n' "CodeQL plan must record completed local verification." >&2
  exit 1
fi

if ! grep -Fq "CodeQL default setup analyzes" "$README" || \
   ! grep -Fq "CodeQL default-setup results" "$ROOT_DIR/SECURITY.md" || \
   ! grep -Fq "CodeQL default-setup coverage" "$ROOT_DIR/VISION.md" || \
   ! grep -Fq "CodeQL default setup" "$ROOT_DIR/CHANGES.md"; then
  printf '%s\n' "Repository guidance must document CodeQL coverage." >&2
  exit 1
fi

if ! cmp -s "$WORKFLOW" "$EXPECTED_WORKFLOW"; then
  printf '%s\n' "Twilio CI must match the approved verification and manual-deployment policy." >&2
  exit 1
fi

for all_branch_doc in "$ROOT_DIR/AGENTS.md" "$README" "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$all_branch_doc" | tr -s '[:space:]' ' ' | \
      grep -Fq 'verification for pushes and pull requests on every branch'; then
    printf '%s\n' "$all_branch_doc must document all-branch verification." >&2
    exit 1
  fi
done

ALL_BRANCH_VERIFICATION_PLAN_FLAT=$(tr '\n' ' ' < "$ALL_BRANCH_VERIFICATION_PLAN" | tr -s '[:space:]' ' ')
for all_branch_plan_contract in \
  'status: completed' \
  'Run the `verify` job for pushes to every branch' \
  'pull requests targeting any branch' \
  'Keep the deploy job restricted to manual dispatch with confirmation on `refs/heads/main`' \
  'Require exact-head push and pull-request hosted verification success' \
  'Seven isolated mutations were rejected' \
  'Exact implementation head `5f3975629c92b2c97d48471675cdd0723d068dcf`' \
  '27680346579' \
  '27680363420' \
  'both protected `deploy` jobs skipped as designed'; do
  if ! printf '%s\n' "$ALL_BRANCH_VERIFICATION_PLAN_FLAT" | grep -Fq "$all_branch_plan_contract"; then
    printf '%s\n' "All-branch verification plan must preserve contract: $all_branch_plan_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "Status: Completed" "$DEPLOYMENT_SAFETY_PLAN" ||
  ! grep -Fq "npm run verify" "$DEPLOYMENT_SAFETY_PLAN"; then
  printf '%s\n' "Deployment safety plan must record completed verification." >&2
  exit 1
fi

if ! grep -Fq "docs/plans/2026-06-10-twilio-deployment-safety.md" "$README"; then
  printf '%s\n' "README must link the Twilio deployment safety plan." >&2
  exit 1
fi

if ! grep -Fq "only deploys from refs/heads/main" "$README"; then
  printf '%s\n' "README must document the main-branch deployment guard." >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/Makefile" ] || \
   ! grep -Fq 'override CONTINUOUS_CLI_ROOT_CHANNEL :=' "$ROOT_DIR/Makefile" || \
   [ "$(grep -Fc '$(call run_npm,' "$ROOT_DIR/Makefile")" -ne 4 ]; then
  printf '%s\n' "Makefile must root all npm verification targets at the repository." >&2
  exit 1
fi

if ! grep -Fq "commit-pinned actions" "$ROOT_DIR/SECURITY.md" ||
  ! grep -Fq "explicit confirmation" "$ROOT_DIR/VISION.md"; then
  printf '%s\n' "Security and vision docs must preserve the deployment safety boundary." >&2
  exit 1
fi

if grep -Eq '^[[:space:]]+[A-Za-z-]+:[[:space:]]+write$' "$WORKFLOW"; then
  printf '%s\n' "Workflow must not grant write permissions." >&2
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

if ! grep -Fq "node-version-file: .nvmrc" "$WORKFLOW"; then
  printf '%s\n' "Workflow must read Node version from .nvmrc." >&2
  exit 1
fi

for package_contract in \
  '"@eslint/js": "10.0.1"' \
  '"eslint": "10.5.0"' \
  '"twilio-run": "5.0.1"' \
  '"audit": "npm audit --audit-level=moderate"'; do
  if ! grep -Fq "$package_contract" "$ROOT_DIR/package.json"; then
    printf '%s\n' "package.json must keep contract: $package_contract" >&2
    exit 1
  fi
done

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

if ! readme_has "directory private asset path"; then
  printf '%s\n' "README must document directory private asset path coverage." >&2
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

if ! readme_has "multiple local TwiML messages inside one Response envelope"; then
  printf '%s\n' "README must document local TwiML response envelope coverage." >&2
  exit 1
fi

if ! readme_has "non-throwing error callbacks complete once without falling through to the success callback" || \
   ! readme_has "Throwing success and error callbacks also propagate their sentinel after one completion"; then
  printf '%s\n' "README must document private-message single-completion coverage." >&2
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

if ! grep -Fq "Status: Completed" "$PRIVATE_ASSET_FILE_PATH_PLAN"; then
  printf '%s\n' "Private asset file path guard plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$PRIVATE_ASSET_FILE_PATH_PLAN"; then
  printf '%s\n' "Private asset file path guard plan must record make check verification." >&2
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

if ! grep -Fq "Status: Completed" "$TWIML_RESPONSE_ENVELOPE_PLAN"; then
  printf '%s\n' "TwiML response envelope plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$TWIML_RESPONSE_ENVELOPE_PLAN"; then
  printf '%s\n' "TwiML response envelope plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-09-private-asset-message-text-guard.md"; then
  printf '%s\n' "Private asset message text guard plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$DEPLOYMENT_REF_PLAN" || \
   ! grep -Fq "npm run verify" "$DEPLOYMENT_REF_PLAN"; then
  printf '%s\n' "Main-branch deployment guard plan must record completed verification." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-private-asset-message-text-guard.md"; then
  printf '%s\n' "Private asset message text guard plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$SINGLE_COMPLETION_PLAN" || \
   ! grep -Fq "make check" "$SINGLE_COMPLETION_PLAN"; then
  printf '%s\n' "Private message single-completion plan must record completed status and make check verification." >&2
  exit 1
fi

"$ROOT_DIR/scripts/test-make-path-boundary.sh"
"$ROOT_DIR/scripts/test-make-version-routing.sh"
"$ROOT_DIR/scripts/test-baseline-working-tree-contract.sh"
node "$ROOT_DIR/scripts/test-run-with-timeout.js"
node "$ROOT_DIR/scripts/check-descriptor-discovery-bundle.js"
node "$ROOT_DIR/scripts/check-descriptor-discovery-lint-contract.js"
node "$ROOT_DIR/scripts/check-descriptor-discovery-test-wiring.js"
node "$ROOT_DIR/scripts/test-descriptor-discovery.js"
"$ROOT_DIR/scripts/test-make-path-boundary-v3-red.sh"
"$ROOT_DIR/scripts/test-make-path-boundary-v4.sh"
"$ROOT_DIR/scripts/test-make-high-fd.sh"
"$ROOT_DIR/scripts/test-make-descriptor-types.sh"
"$ROOT_DIR/scripts/test-make-proc-simulation.sh"
"$ROOT_DIR/scripts/test-make-lsof-output.sh"
"$ROOT_DIR/scripts/test-make-proc-large-output.sh"
"$ROOT_DIR/scripts/test-make-lsof-truncation.sh"
"$ROOT_DIR/scripts/test-make-linux-authority-mutations.sh"
"$ROOT_DIR/scripts/test-make-path-boundary-mutations.sh"

if [ "${CONTINUOUS_CLI_SHALLOW_BASELINE_ACTIVE:-}" != 1 ]; then
  "$ROOT_DIR/scripts/test-copy-tracked-worktree.sh"
  "$ROOT_DIR/scripts/test-copy-tar-portability.sh"
  "$ROOT_DIR/scripts/test-copy-tar-portability-mutation.sh"
  "$ROOT_DIR/scripts/test-shallow-baseline.sh"
  "$ROOT_DIR/scripts/test-shallow-baseline-mutation.sh"
fi

printf '%s\n' "continuous-cli-101 Twilio baseline checks passed."
