Stripe.enable_telemetry = false
Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key)
