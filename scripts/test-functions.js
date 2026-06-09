const assert = require("assert");
const path = require("path");

function MessagingResponse() {
  this.messages = [];
}

MessagingResponse.prototype.message = function message(body) {
  this.messages.push(String(body));
};

MessagingResponse.prototype.toString = function toString() {
  return this.messages.map(function renderMessage(body) {
    return "<Response><Message>" + body + "</Message></Response>";
  }).join("");
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

async function run() {
  const helloWorld = require("../functions/hello-world").handler;
  const privateMessage = require("../functions/private-message").handler;
  const smsReply = require("../functions/sms/reply.protected").handler;

  const helloResult = await invoke(helloWorld);
  assert.deepStrictEqual(helloResult, {
    message: "Hello CLI 101 Training from Wednesday"
  });

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
}

run()
  .then(function() {
    console.log("Twilio function tests passed.");
  })
  .catch(function(error) {
    console.error(error);
    process.exit(1);
  });
