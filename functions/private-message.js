exports.handler = function(context, event, callback) {
  try {
    const assets = Runtime.getAssets();
    const privateMessageAsset = assets && assets['/message.js'];
    if (!privateMessageAsset || !privateMessageAsset.path) {
      callback(new Error('Private message asset /message.js is not available.'));
      return;
    }

    const privateMessage = require(privateMessageAsset.path);
    if (typeof privateMessage !== 'function') {
      callback(new Error('Private message asset /message.js must export a function.'));
      return;
    }

    const message = privateMessage();
    if (typeof message !== 'string' || message.trim() === '') {
      callback(new Error('Private message asset /message.js must return a non-empty string.'));
      return;
    }

    const twiml = new Twilio.twiml.MessagingResponse();
    twiml.message(message);
    callback(null, twiml);
  } catch (error) {
    callback(error);
  }
};
