# frozen_string_literal: true

class SubscriptionMailer < ApplicationMailer
  def confirm_subscription(subscription)
    @subscription = subscription

    mail to: subscription.member.email,
         cc: cc_emails(subscription),
         subject: "Inscription Parkour Paris #{subscription.year} / #{subscription.year + 1}"
  end

  def confirm_camp_subscription(subscription)
    @subscription = subscription

    mail to: subscription.member.email,
         cc: cc_emails(subscription),
         subject: "Inscription Stage Parkour Paris - #{subscription.camp.title}"
  end

  def confirm_discovery_subscription(subscription)
    @subscription = subscription

    mail to: subscription.member.email,
         cc: cc_emails(subscription),
         subject: "Inscription Cours découverte Parkour Paris - #{subscription.discovery_session.course.title}"
  end

  private

  def cc_emails(subscription)
    subscription.member.contacts.pluck(:email)
  end
end
