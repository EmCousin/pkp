# frozen_string_literal: true

module Auth
  class Mailer < ApplicationMailer
    default from: 'noreply@parkourparis.fr'

    def reset_password_instructions(user, token)
      @user = user
      @token = token
      mail to: user.email, subject: t('auth.mailer.reset_password_instructions.subject')
    end

    def unlock_instructions(user, token)
      @user = user
      @token = token
      mail to: user.email, subject: t('auth.mailer.unlock_instructions.subject')
    end

    def password_changed(email)
      @email = email
      mail to: email, subject: t('auth.mailer.password_changed.subject')
    end

    def email_changed(previous_email, email)
      @previous_email = previous_email
      @email = email
      mail to: previous_email, subject: t('auth.mailer.email_changed.subject')
    end
  end
end
