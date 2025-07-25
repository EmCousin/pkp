# frozen_string_literal: true

module Subscriptions
  module QrEncodeable
    def qr_code_svg
      @qr_code_svg ||= qr_code.as_svg(
        color: '000',
        shape_rendering: 'crispEdges',
        module_size: 11,
        standalone: true,
        use_path: true
      )
    end

    private

    def qr_code
      RQRCode::QRCode.new(qr_code_data)
    end

    def qr_code_data
      Rails.application.routes.url_helpers.admin_subscription_url(self, host: Rails.application.config.action_mailer.default_url_options[:host])
    end
  end
end
