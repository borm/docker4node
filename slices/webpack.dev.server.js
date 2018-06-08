/* eslint-disable no-console */
import express from 'express';
import webpack from 'webpack';
import webpackDevMiddleware from 'webpack-dev-middleware';
import webpackHotMiddleware from 'webpack-hot-middleware';
// import path from 'path';

import webpackConfig from './webpack.config.babel';
import config from './config';

const { host, port } = config;
console.log('Starting devServer on: %j', `http://${host}:${port}`);
const app = express();

const compiler = webpack(webpackConfig);
let bundleStart = null;
// We give notice in the terminal when it starts bundling and
// set the time it started
compiler.plugin('compile', () => {
  console.log('Bundling...');
  bundleStart = Date.now();
});

// We also give notice when it is done compiling, including the
// time it took. Nice to have
compiler.plugin('done', () => {
  console.log(`Bundled in ${Date.now() - bundleStart}ms!`);
});
const middleware = webpackDevMiddleware(compiler, {
  quiet: false,
  noInfo: false,
  hot: true,
  inline: true,
  lazy: false,
  headers: { 'Access-Control-Allow-Origin': '*' },
  publicPath: webpackConfig.output.publicPath,
  contentBase: 'src',
  stats: {
    colors: true,
    hash: false,
    timings: true,
    chunks: false,
    chunkModules: false,
    modules: false,
  },
});

app.use(middleware);
app.use(webpackHotMiddleware(compiler));

app.use((req, res, next) => {
  res.append('Access-Control-Allow-Origin', ['*']);
  res.append('Access-Control-Allow-Methods', 'GET,POST');
  res.append('Access-Control-Allow-Headers', ['*']);
  next();
});

app.get('/', (req, res, next) => {
    res.send('Hello world!');
    next();
});

app.get('/dist/*', (req, res, next) => {
  console.log(req.url);
  res.append('Content-Type', 'application/javascript;');
  next();
});

app.listen(port, (err) => {
  if (err) {
    console.log(err);
  }
});
