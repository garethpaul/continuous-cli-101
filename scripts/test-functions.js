const assert = require("assert");
const path = require("path");
const {clearTimeout, setTimeout} = require("node:timers");

const DEFAULT_CALLBACK_TIMEOUT_MS = 5000;

function MessagingResponse() {
  this.messages = [];
}

function escapeXml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

MessagingResponse.prototype.message = function message(body) {
  this.messages.push(String(body));
};

MessagingResponse.prototype.toString = function toString() {
  const messages = this.messages.map(function renderMessage(body) {
    return "<Message>" + escapeXml(body) + "</Message>";
  }).join("");

  return "<Response>" + messages + "</Response>";
};

function invoke(handler, options) {
  options = options || {};

  return new Promise(function(resolve, reject) {
    const previousTwilio = global.Twilio;
    const previousRuntime = global.Runtime;
    const callbackTimeoutMs = Number.isFinite(options.timeoutMs) && options.timeoutMs > 0 ?
      options.timeoutMs : DEFAULT_CALLBACK_TIMEOUT_MS;
    let settled = false;
    let timeoutId;

    function restoreGlobals() {
      if (previousTwilio === undefined) {
        delete global.Twilio;
      } else {
        global.Twilio = previousTwilio;
      }

      if (previousRuntime === undefined) {
        delete global.Runtime;
      } else {
        global.Runtime = previousRuntime;
      }
    }

    function settle(operation) {
      if (settled) {
        return;
      }

      settled = true;
      clearTimeout(timeoutId);
      restoreGlobals();
      operation();
    }

    global.Twilio = {
      twiml: {
        MessagingResponse: MessagingResponse
      }
    };

    global.Runtime = {
      getAssets: function getAssets() {
        return Object.prototype.hasOwnProperty.call(options, "assets") ? options.assets : {};
      }
    };

    timeoutId = setTimeout(function handleCallbackTimeout() {
      settle(function rejectCallbackTimeout() {
        reject(new Error(
          "Twilio handler did not invoke its callback within " + callbackTimeoutMs + "ms."
        ));
      });
    }, callbackTimeoutMs);

    try {
      handler(options.context || {}, options.event || {}, function callback(error, result) {
        settle(function completeCallback() {
          if (options.expectError) {
            try {
              assert(error instanceof Error);
              assert.strictEqual(result, undefined);
              resolve(error);
            } catch (assertionError) {
              reject(assertionError);
            }
            return;
          }

          if (error) {
            reject(error);
            return;
          }

          resolve(result);
        });
      });
    } catch (error) {
      settle(function rejectSynchronousFailure() {
        reject(error);
      });
    }
  });
}

function withRuntimeGlobals(options, operation) {
  const previousTwilio = global.Twilio;
  const previousRuntime = global.Runtime;

  global.Twilio = {
    twiml: {
      MessagingResponse: MessagingResponse
    }
  };
  global.Runtime = {
    getAssets: function getAssets() {
      return options.assets;
    }
  };

  try {
    return operation();
  } finally {
    if (previousTwilio === undefined) {
      delete global.Twilio;
    } else {
      global.Twilio = previousTwilio;
    }

    if (previousRuntime === undefined) {
      delete global.Runtime;
    } else {
      global.Runtime = previousRuntime;
    }
  }
}

function invokeWithThrowingCallback(handler, options) {
  const callbackFailure = new Error("Callback failure sentinel.");
  const calls = [];

  withRuntimeGlobals(options, function invokeWithGlobals() {
    assert.throws(function invokeHandler() {
      handler({}, {}, function throwingCallback(error, result) {
        calls.push({error: error, result: result});
        throw callbackFailure;
      });
    }, function isCallbackFailure(error) {
      return error === callbackFailure;
    });
  });

  return calls;
}

function invokeWithRecordingCallback(handler, options) {
  const calls = [];

  withRuntimeGlobals(options, function invokeWithGlobals() {
    handler({}, {}, function recordingCallback(error, result) {
      calls.push({error: error, result: result});
    });
  });

  return calls;
}

async function run() {
  const helloWorld = require("../functions/hello-world").handler;
  const privateMessage = require("../functions/private-message").handler;
  const smsReply = require("../functions/sms/reply.protected").handler;

  const helloResult = await invoke(helloWorld);
  assert.deepStrictEqual(helloResult, {
    message: "Hello CLI 101 Training from Wednesday"
  });

  const escapedResponse = new MessagingResponse();
  escapedResponse.message("A&B <C> \"quote\" 'apostrophe'");
  assert.strictEqual(
    escapedResponse.toString(),
    "<Response><Message>A&amp;B &lt;C&gt; &quot;quote&quot; &apos;apostrophe&apos;</Message></Response>"
  );

  const multiMessageResponse = new MessagingResponse();
  multiMessageResponse.message("First");
  multiMessageResponse.message("Second");
  assert.strictEqual(
    multiMessageResponse.toString(),
    "<Response><Message>First</Message><Message>Second</Message></Response>"
  );

  const smsResult = await invoke(smsReply);
  assert.strictEqual(smsResult.toString(), "<Response><Message>Hello World!</Message></Response>");

  const privateMessagePath = path.join(__dirname, "../assets/message.private.js");
  const privateResult = await invoke(privateMessage, {
    assets: {
      "/message.js": {
        path: privateMessagePath
      }
    }
  });
  assert.strictEqual(
    privateResult.toString(),
    "<Response><Message>This is private!</Message></Response>"
  );

  const throwingSuccessCalls = invokeWithThrowingCallback(privateMessage, {
    assets: {
      "/message.js": {
        path: privateMessagePath
      }
    }
  });
  assert.strictEqual(throwingSuccessCalls.length, 1);
  assert.strictEqual(throwingSuccessCalls[0].error, null);
  assert.strictEqual(
    throwingSuccessCalls[0].result.toString(),
    "<Response><Message>This is private!</Message></Response>"
  );

  const throwingErrorCalls = invokeWithThrowingCallback(privateMessage, {assets: {}});
  assert.strictEqual(throwingErrorCalls.length, 1);
  assert.strictEqual(
    throwingErrorCalls[0].error.message,
    "Private message asset /message.js is not available."
  );
  assert.strictEqual(throwingErrorCalls[0].result, undefined);

  const recordingErrorCalls = invokeWithRecordingCallback(privateMessage, {assets: {}});
  assert.strictEqual(recordingErrorCalls.length, 1);
  assert.strictEqual(
    recordingErrorCalls[0].error.message,
    "Private message asset /message.js is not available."
  );
  assert.strictEqual(recordingErrorCalls[0].result, undefined);

  const missingAssetError = await invoke(privateMessage, {
    assets: {},
    expectError: true
  });
  assert.strictEqual(missingAssetError.message, "Private message asset /message.js is not available.");

  const nullAssetsError = await invoke(privateMessage, {
    assets: null,
    expectError: true
  });
  assert.strictEqual(nullAssetsError.message, "Private message asset /message.js is not available.");

  const blankAssetPathError = await invoke(privateMessage, {
    assets: {
      "/message.js": {
        path: "   "
      }
    },
    expectError: true
  });
  assert.strictEqual(blankAssetPathError.message, "Private message asset /message.js is not available.");

  const relativeAssetPathError = await invoke(privateMessage, {
    assets: {
      "/message.js": {
        path: "assets/message.private.js"
      }
    },
    expectError: true
  });
  assert.strictEqual(relativeAssetPathError.message, "Private message asset /message.js is not available.");

  const directoryAssetPathError = await invoke(privateMessage, {
    assets: {
      "/message.js": {
        path: __dirname
      }
    },
    expectError: true
  });
  assert.strictEqual(directoryAssetPathError.message, "Private message asset /message.js is not available.");

  const nonFunctionMessagePath = path.join(__dirname, "fixtures/non-function-message.js");
  const nonFunctionAssetError = await invoke(privateMessage, {
    assets: {
      "/message.js": {
        path: nonFunctionMessagePath
      }
    },
    expectError: true
  });
  assert.strictEqual(
    nonFunctionAssetError.message,
    "Private message asset /message.js must export a function."
  );

  const blankMessagePath = path.join(__dirname, "fixtures/blank-message.js");
  const blankMessageError = await invoke(privateMessage, {
    assets: {
      "/message.js": {
        path: blankMessagePath
      }
    },
    expectError: true
  });
  assert.strictEqual(
    blankMessageError.message,
    "Private message asset /message.js must return a non-empty string."
  );

  let missingCallbackError;
  try {
    await invoke(function neverCallsBack() {}, {timeoutMs: 10});
    assert.fail("A handler that never calls back must fail the test harness.");
  } catch (error) {
    missingCallbackError = error;
  }
  assert.strictEqual(
    missingCallbackError.message,
    "Twilio handler did not invoke its callback within 10ms."
  );

  const synchronousTwilioSentinel = {name: "synchronous-twilio"};
  const synchronousRuntimeSentinel = {name: "synchronous-runtime"};
  global.Twilio = synchronousTwilioSentinel;
  global.Runtime = synchronousRuntimeSentinel;
  let synchronousHandlerError;
  try {
    await invoke(function throwSynchronously() {
      throw new Error("Synchronous handler failure sentinel.");
    });
  } catch (error) {
    synchronousHandlerError = error;
  }
  assert.strictEqual(synchronousHandlerError.message, "Synchronous handler failure sentinel.");
  assert.strictEqual(global.Twilio, synchronousTwilioSentinel);
  assert.strictEqual(global.Runtime, synchronousRuntimeSentinel);

  const timeoutTwilioSentinel = {name: "timeout-twilio"};
  const timeoutRuntimeSentinel = {name: "timeout-runtime"};
  global.Twilio = timeoutTwilioSentinel;
  global.Runtime = timeoutRuntimeSentinel;
  let lateCallback;
  try {
    await invoke(function captureLateCallback(context, event, callback) {
      lateCallback = callback;
    }, {timeoutMs: 10});
  } catch (error) {
    assert.strictEqual(
      error.message,
      "Twilio handler did not invoke its callback within 10ms."
    );
  }
  assert.strictEqual(global.Twilio, timeoutTwilioSentinel);
  assert.strictEqual(global.Runtime, timeoutRuntimeSentinel);

  const postTimeoutTwilioSentinel = {name: "post-timeout-twilio"};
  const postTimeoutRuntimeSentinel = {name: "post-timeout-runtime"};
  global.Twilio = postTimeoutTwilioSentinel;
  global.Runtime = postTimeoutRuntimeSentinel;
  lateCallback(null, "late result");
  assert.strictEqual(global.Twilio, postTimeoutTwilioSentinel);
  assert.strictEqual(global.Runtime, postTimeoutRuntimeSentinel);
  delete global.Twilio;
  delete global.Runtime;
}

run()
  .then(function() {
    console.log("Twilio function tests passed.");
  })
  .catch(function(error) {
    console.error(error);
    process.exit(1);
  });
