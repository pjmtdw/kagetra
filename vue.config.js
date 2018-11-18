module.exports = {
  outputDir: 'static',
  filenameHashing: false,
  productionSourceMap: process.env.NODE_ENV !== 'production',
  chainWebpack(config) {
    config.plugins.delete('html');
    config.plugins.delete('preload');
    config.plugins.delete('prefetch');
    config.optimization.delete('splitChunks');
    config.output.filename('js/bundle.js');
  },
};
