var exec = require('cordova/exec');

exports.openPhotoLibrary = function(arg0, success, error) {
    exec(success, error, "YHImagePicker", "openPhotoLibrary", [arg0]);
};
