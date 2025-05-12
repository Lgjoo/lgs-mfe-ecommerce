const { shareAll, withModuleFederationPlugin } = require('@angular-architects/module-federation/webpack');

module.exports = withModuleFederationPlugin({

  remotes: {
    "lgs-mfe-catalog": "https://lgs-mfe-catalog.onrender.com/remoteEntry.js",
    "lgs-mfe-cart": "https://lgs-mfe-cart.onrender.com/remoteEntry.js"   
  },

  shared: {
    ...shareAll({ singleton: true, strictVersion: true, requiredVersion: 'auto' }),
  },

});
