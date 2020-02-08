# frozen_string_literal: true

class SubscriptionsMailbox < ApplicationMailbox
  # Callbacks specify prerequisites to processing
  before_processing :ensure_user!

  def process; end

  private

  def ensure_user!
    return if user.present?

    bounce_with UserMailer.missing(inbound_email)
  end

  def user
    @user ||= User.find_by(email: mail.from)
  end
end
