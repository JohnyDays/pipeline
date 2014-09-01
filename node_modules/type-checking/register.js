// Returns a function you have to call in order to register on the object prototype, with an optional key
module.exports = function(key) {
  if (key == null) {
    key = 'responds_to';
  }
  _implements = require('./index.js');
  Object.prototype[key] = function(what){return _implements(this, what)};
}
