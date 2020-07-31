# frozen_string_literal: true

class SubscriptionMailer < ApplicationMailer
  def confirm_subscription(subscription)
    @subscription = subscription

    attachments['fiche.pdf'] = {
      mime_type: subscription.form.blob.content_type,
      content: subscription.form.blob.download
    }

    mail to: subscription.member.email, subject: "Inscription Parkour Paris #{subscription.year} / #{subscription.year + 1}"
  end
end
