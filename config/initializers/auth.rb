# frozen_string_literal: true

require Rails.root.join('lib/auth')

Auth.configure do |config|
  config.inactivity_timeout = 1.week
  config.mailer_sender = 'noreply@parkourparis.fr'
  config.maximum_attempts = 20
  config.password_length = 8..128
  config.unlock_in = 10.minutes
end
