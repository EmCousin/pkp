# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def missing(_inbound_email)
    mail(to: 'missing@parkourparis.fr')
  end
end
