# frozen_string_literal: true

class ContactMailer < ApplicationMailer
  def confirmation_instructions(contact)
    @contact = contact
    mail(to: contact.email)
  end
end
