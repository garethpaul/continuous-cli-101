# Private Message Serialization Implementation Plan

Status: Completed

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Reject private asset message text that cannot be serialized as TwiML before reporting callback success.

**Architecture:** Keep validation inside `functions/private-message.js` and reuse the active `MessagingResponse` implementation as the authority for XML/TwiML validity. Build the response, force one `toString()` serialization inside the existing catchable computation block, and preserve the single error and success callback sites.

**Tech Stack:** Node.js 22, Twilio Serverless/TwiML, JavaScript, ESLint, GNU Make.

---

### Task 1: Prove Post-Callback Serialization Failure

**Files:**
- Create: `scripts/fixtures/invalid-xml-message.js`
- Modify: `scripts/test-functions.js`

**Step 1: Write the failing regression**

Add a private asset fixture returning `"Invalid\u0000message"`. Make the local `MessagingResponse.toString()` reject XML-disallowed control characters, then assert `private-message` completes with that error rather than a successful TwiML object.

**Step 2: Run the focused test to verify it fails**

Run: `node scripts/test-functions.js`

Expected: FAIL because `private-message` currently never serializes the TwiML object before callback success.

### Task 2: Validate TwiML Before Success

**Files:**
- Modify: `functions/private-message.js`
- Modify: `scripts/test-functions.js`

**Step 1: Write minimal implementation**

Call `twiml.toString()` immediately after `twiml.message(message)` inside the existing `try` block. Any production serialization failure then flows through the existing single `callback(error)` site.

**Step 2: Run focused tests**

Run: `node scripts/test-functions.js`

Expected: PASS, including the invalid XML fixture and all callback-count regressions.

### Task 3: Preserve The Durable Contract

**Files:**
- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `SECURITY.md`
- Modify: `VISION.md`
- Modify: `CHANGES.md`
- Modify: `scripts/check-baseline.sh`
- Modify: `docs/plans/2026-06-26-private-message-serialization.md`

**Step 1: Document the boundary**

State that private message TwiML must serialize successfully before callback success, preserving the one-error/one-success completion structure.

**Step 2: Add mutation-sensitive contracts**

Require the serialization call before the success callback, the invalid fixture/regression, synchronized guidance, and completed plan evidence.

**Step 3: Run complete verification**

Run: `make check`

Expected: ESLint, function tests, source baseline, npm audit, build checks, and hostile Make path matrices pass under Node 22.

**Step 4: Commit**

Run: `git add functions/private-message.js scripts/test-functions.js scripts/fixtures/invalid-xml-message.js scripts/check-baseline.sh AGENTS.md README.md SECURITY.md VISION.md CHANGES.md docs/plans/2026-06-26-private-message-serialization.md && git commit -m "fix: validate private message TwiML serialization"`

## Verification Completed

- A direct probe with the installed Twilio library reproduced an `Invalid
  character in string` serialization error for a NUL-containing message.
- A Node 22 production-library callback probe passed, proving the fixed handler
  reports that serialization failure once with no success result.
- The focused function harness failed before implementation because the
  function reported callback success without serializing, then passed after
  `twiml.toString()` moved inside the existing error boundary.
- Node 22.13.0 clean installation, ESLint, function tests, and the
  moderate-severity npm audit passed with zero vulnerabilities.
- Eight isolated hostile mutations were rejected for missing/non-invoked
  serialization, missing production-shaped XML rejection, missing regression,
  missing fixture, removed public guidance, stale plan status, and a missing
  source serialization contract.
- `make check` passed under Node 22.13.0, including ESLint, function tests,
  source contracts, zero-vulnerability audit, checkout-path matrices, shallow
  baseline verification, and the existing hostile Make mutations.
