require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Pkp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.i18n.default_locale = :fr

    config.add_autoload_paths_to_load_path = false

    config.autoload_paths << "#{root}/app/form_builders"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.middleware.insert_before 0, Rack::Cors do
      unless Rails.env.test?
        allow do
          origins '*'
          resource '*', headers: :any, methods: %I[get]
        end
      end
    end

    config.action_dispatch.default_headers.merge!("Permissions-Policy" => "interest-cohort=()")
  end
end
