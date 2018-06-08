import fs from 'fs';
import webpack from 'webpack';
import UglifyJSPlugin from 'uglifyjs-webpack-plugin';
import config from './config';
//import { BundleAnalyzerPlugin } from 'webpack-bundle-analyzer';

const babelRc = JSON.parse(fs.readFileSync('./.babelrc'));

const {
  env, source, output, uri, publicPath, themePath,
} = config;
const isDev = env === 'development';
const isProd = env === 'production';

const hot = [
  `webpack-hot-middleware/client?path=${uri}/__webpack_hmr`,
];

global.PUBLIC_PATH = publicPath;
global.THEME_PATH = themePath;

const webpackConfig = {
  devtool: 'source-map',
  mode: env,
  target: 'web',
  context: source,
  resolve: {
    modules: [
      source,
      'node_modules',
    ],
    extensions: ['.js', '.jsx', '.scss'],
  },
  entry: {
    app: ((app) => {
      if (isDev) {
        return [...hot, ...app];
      }
      return app;
    })(['babel-polyfill', './index.js']),
  },
  output: {
    path: output,
    filename: `dist/[name]${isProd ? '.min' : ''}.js`,
    chunkFilename: `dist/[name]${isProd ? '.min' : ''}.js`,
    publicPath: '/',
  },
  module: {
    rules: (rules => rules)([{
      test: /\.(js|jsx)$/,
      exclude: [/node_modules/],
      use: [{
        loader: 'babel-loader',
        options: {
          cacheDirectory: true,
          presets: babelRc.presets,
          plugins: babelRc.plugins,
        },
      }],
    }]),
  },
  plugins: ((plugins) => {
    if (isDev) {
      plugins.push(
        new webpack.HotModuleReplacementPlugin(),
      );
    }
    return plugins;
  })([
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify(env),
      },
      PUBLIC_PATH: JSON.stringify(publicPath),
      THEME_PATH: JSON.stringify(themePath),
    }),
    new webpack.ProvidePlugin({
      Promise: 'es6-promise',
    }),
  ]),
  optimization: {
    minimizer: [
      new UglifyJSPlugin({
        uglifyOptions: {
          output: {
            comments: false,
          },
          compress: {
            warnings: false,
            dead_code: true,
            drop_debugger: true,
            drop_console: true,
            inline: false,
          },
        },
      }),
    ],
  },
};

export default webpackConfig;
