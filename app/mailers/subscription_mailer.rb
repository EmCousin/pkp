# frozen_string_literal: true

class SubscriptionMailer < ApplicationMailer
  def confirm_subscription(subscription)
    @subscription = subscription

    pdf = pdf_from_subscription(subscription)

    attachments['fiche.pdf'] = { mime_type: 'application/pdf', content: pdf.force_encoding('UTF-8') }

    mail to: subscription.member.email, subject: "Inscription Parkour Paris #{subscription.year} / #{subscription.year + 1}"
  end

  private

  def pdf_from_subscription(subscription)
    WickedPdf.new.pdf_from_string(
      render_to_string(
        'templates/subscription.html.erb',
        layout: 'pdf.html.erb',
        encoding: 'UTF-8',
        locals: {
          subscription: subscription
        }
      )
    )
  end
end
