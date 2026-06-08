exports.handler = function(context, event, callback) {
  try {
    const assets = Runtime.getAssets();
    const privateMessageAsset = assets['/message.js'];
    if (!privateMessageAsset || !privateMessageAsset.path) {
      callback(new Error('Private message asset /message.js is not available.'));
      return;
    }

    const privateMessage = require(privateMessageAsset.path);
    const twiml = new Twilio.twiml.MessagingResponse();
    twiml.message(privateMessage());
    callback(null, twiml);
  } catch (error) {
    callback(error);
  }
};
