exports.handler = function(context, event, callback) {
  const result = {
    message: "Hello CLI 101 Training from Wednesday"
  }

  callback(null, result);
};
