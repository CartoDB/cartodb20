const path = require('path');
const webpack = require('webpack');

module.exports = {
  entry: './src/api/v4/index.js',
  output: {
    path: path.resolve(__dirname, 'dist/public'),
    filename: 'carto.js',
    library: 'carto',
    libraryTarget: 'umd'
  },
  plugins: [
    // Include only the lastest camshaft-reference
    new webpack.IgnorePlugin(/^\.\/((?!0\.59\.4).)*\/reference\.json$/)
  ],
  // Do not to include Leaflet in the bundle
  externals: {
    leaflet: 'L'
  }
};
