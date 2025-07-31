# frozen_string_literal: true

class User < ApplicationRecord
  INVALID_EMAIL_PROVIDERS = %w[@wanadoo.fr @orange.fr].freeze

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :lockable,
         :timeoutable

  include Users::AdminNotifiable
  include Users::Chargeable

  has_many :contacts, dependent: :destroy
  accepts_nested_attributes_for :contacts, reject_if: :all_blank, allow_destroy: true

  has_many :members, dependent: :destroy
  has_many :subscriptions, through: :members
  has_many :courses, through: :subscriptions

  attr_accessor :email_confirmation

  validates :email, confirmation: true, if: :email_confirmation_required?
  validate :valid_email_provider, if: :email?, on: :create
  validates :terms_of_service, acceptance: true

  with_options on: :account_setup do
    validates :phone_number, :address, :zip_code, :city, :country, presence: true
    validates :phone_number, phone: true
  end

  def full_address
    [
      address,
      "#{zip_code} #{city}",
      country
    ].join("\n")
  end

  def invalid_email_provider?
    INVALID_EMAIL_PROVIDERS.any? { |provider| email.ends_with?(provider) }
  end

  private

  def email_confirmation_required?
    new_record? && email.present? && email_confirmation.present?
  end

  def valid_email_provider
    errors.add(:email, :invalid_provider) if invalid_email_provider?
  end
end
