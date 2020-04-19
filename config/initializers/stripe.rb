Stripe.enable_telemetry = false
Stripe.api_key = Rails.application.credentials.stripe[:secret_key]
