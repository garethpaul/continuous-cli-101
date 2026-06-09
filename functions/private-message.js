const fs = require('fs');
const path = require('path');

function isReadableFile(assetPath) {
  try {
    const stats = fs.statSync(assetPath);
    fs.accessSync(assetPath, fs.constants.R_OK);
    return stats.isFile();
  } catch {
    return false;
  }
}

exports.handler = function(context, event, callback) {
  try {
    const assets = Runtime.getAssets();
    const privateMessageAsset = assets && assets['/message.js'];
    if (!privateMessageAsset || typeof privateMessageAsset.path !== 'string' ||
        privateMessageAsset.path.trim() === '' ||
        !path.isAbsolute(privateMessageAsset.path) ||
        !isReadableFile(privateMessageAsset.path)) {
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
