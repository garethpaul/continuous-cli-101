const assert = require("assert");
const path = require("path");

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

    try {
      handler(options.context || {}, options.event || {}, function callback(error, result) {
        restoreGlobals();

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
    } catch (error) {
      restoreGlobals();
      reject(error);
    }
  });
}

function invokeWithThrowingCallback(handler, options) {
  const previousTwilio = global.Twilio;
  const previousRuntime = global.Runtime;
  const callbackFailure = new Error("Callback failure sentinel.");
  const calls = [];

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
    assert.throws(function invokeHandler() {
      handler({}, {}, function throwingCallback(error, result) {
        calls.push({error: error, result: result});
        throw callbackFailure;
      });
    }, function isCallbackFailure(error) {
      return error === callbackFailure;
    });
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
}

run()
  .then(function() {
    console.log("Twilio function tests passed.");
  })
  .catch(function(error) {
    console.error(error);
    process.exit(1);
  });
