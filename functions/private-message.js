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
  let twiml;

  try {
    const assets = Runtime.getAssets();
    const privateMessageAsset = assets && assets['/message.js'];
    if (!privateMessageAsset || typeof privateMessageAsset.path !== 'string' ||
        privateMessageAsset.path.trim() === '' ||
        !path.isAbsolute(privateMessageAsset.path) ||
        !isReadableFile(privateMessageAsset.path)) {
      throw new Error('Private message asset /message.js is not available.');
    }

    const privateMessage = require(privateMessageAsset.path);
    if (typeof privateMessage !== 'function') {
      throw new Error('Private message asset /message.js must export a function.');
    }

    const message = privateMessage();
    if (typeof message !== 'string' || message.trim() === '') {
      throw new Error('Private message asset /message.js must return a non-empty string.');
    }

    twiml = new Twilio.twiml.MessagingResponse();
    twiml.message(message);
    twiml.toString();
  } catch (error) {
    callback(error);
    return;
  }

  callback(null, twiml);
};
