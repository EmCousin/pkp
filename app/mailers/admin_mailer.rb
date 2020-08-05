# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  def email_changed(email_was, email)
    @email_was = email_was
    @email = email

    mail to: "contact@parkourparis.fr", subject: t('.subject')
  end
end
