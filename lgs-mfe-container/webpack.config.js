const { shareAll, withModuleFederationPlugin } = require('@angular-architects/module-federation/webpack');

module.exports = withModuleFederationPlugin({

  remotes: {
    "lgs-mfe-catalog": "http://localhost:4201/remoteEntry.js",
    "lgs-mfe-cart": "http://localhost:4202/remoteEntry.js"   
  },

  shared: {
    ...shareAll({ singleton: true, strictVersion: true, requiredVersion: 'auto' }),
  },
});
