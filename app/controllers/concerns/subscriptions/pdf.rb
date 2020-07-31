# frozen_string_literal: true

module Subscriptions
  module Pdf
    extend ActiveSupport::Concern

    private

    def process_after_save(subscription)
      subscription.form.attach(
        io: StringIO.new(pdf_from_subscription(subscription)),
        filename: 'fiche.pdf',
        content_type: Mime[:pdf]
      )

      SubscriptionMailer.confirm_subscription(subscription).deliver_later
    end

    def pdf_from_subscription(subscription)
      WickedPdf.new.pdf_from_string(
        render_to_string(
          'templates/subscription.html.erb',
          layout: 'pdf.html.erb',
          encoding: 'UTF-8',
          locals: { subscription: subscription }
        )
      ).force_encoding('UTF-8')
    end
  end
end
