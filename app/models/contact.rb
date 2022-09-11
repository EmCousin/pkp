# frozen_string_literal: true

class Contact < ApplicationRecord
  belongs_to :user

  validates :email, presence: true, format: { with: Devise.email_regexp }

  after_create :send_email_confirmation_instructions
  before_update :send_email_confirmation_instructions, if: :will_save_change_to_email?

  scope :confirmed, -> { where.not(confirmed_at: :nil) }

  def confirmed?
    confirmed_at?
  end

  private

  def send_email_confirmation_instructions
    ContactMailer.confirmation_instructions(self).deliver_later
  end
end
