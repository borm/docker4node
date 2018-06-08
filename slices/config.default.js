import path from 'path';

const config = {
  env: process.env.NODE_ENV,
  host: '127.0.0.1',
  port: 3000,
  source: path.resolve(__dirname, 'src'),
  output: path.resolve(__dirname),
  // Used as publicPath in webpack.config for production build
  themePath: '/themes/custom/gdesktop/html/',
  // Used in src as publicPath to static files
  publicPath: '/',
};

const { host, port } = config;

config.uri = `http://${host}:${port}`;

export default config;
