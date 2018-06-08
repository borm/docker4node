/* eslint-disable global-require, import/no-mutable-exports */
let config;

try {
  config = require('./config.local').default;
} catch (e) {
  console.warn('Local config not found, please make copy ./config.default as ./config.local');
  config = require('./config.default').default;
}

export default config;
