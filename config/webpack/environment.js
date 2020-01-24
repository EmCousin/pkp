const { environment } = require('@rails/webpacker');
const webpack = require('webpack');

// Add an additional plugin of your choosing : ProvidePlugin
environment.plugins.prepend(
  'Provide',
  new webpack.ProvidePlugin({
    $:         'jquery',
    JQuery:    'jquery',
    jquery:    'jquery',
    Popper:    ['popper.js', 'default'], // for Bootstrap 4
  }),
);

environment.plugins.prepend(
  'Environment',
  new webpack.EnvironmentPlugin(
    JSON.parse(
      JSON.stringify({
        RAILS_ENV: process.env.RAILS_ENV,
        // add as many env vars as you need
      })
    )
  )
);

module.exports = environment;
