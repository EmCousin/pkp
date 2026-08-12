# frozen_string_literal: true

class User < ApplicationRecord
  INVALID_EMAIL_PROVIDERS = %w[@wanadoo.fr @orange.fr].freeze
  COUNTRY_CODES = YAML.safe_load_file(Rails.root.join('config/country_codes.yml')).freeze

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :lockable,
         :timeoutable

  include Users::AdminNotifiable
  include Users::Chargeable
  include Subscriptions::ProtectsFinalizedRegistrations

  has_many :contacts, dependent: :destroy
  accepts_nested_attributes_for :contacts, reject_if: :all_blank, allow_destroy: true

  has_many :members, dependent: :destroy
  has_many :subscriptions, through: :members
  has_many :current_year_subscriptions, lambda {
    confirmed.where(type: AnnualSubscription.sti_name, year: Subscription.current_year, parent_subscription: nil)
  }, through: :members, source: :subscriptions
  has_many :courses, through: :subscriptions

  attr_accessor :email_confirmation

  validates :email, confirmation: true, if: :email_confirmation_required?
  validate :valid_email_provider, if: :email?, on: :create
  validates :terms_of_service, acceptance: true
  validates :first_name, :last_name, presence: true
  validates :country, inclusion: { in: TZInfo::Country.all_codes }, allow_blank: true

  with_options on: :account_setup do
    validates :phone_number, :address, :zip_code, :city, :country, presence: true
    validates :phone_number, phone: true
  end

  normalizes :first_name, :last_name, with: ->(name) { name.strip.downcase.titleize }
  normalizes :country, with: lambda { |country|
    normalized_country = country.strip
    COUNTRY_CODES.fetch(normalized_country.downcase, normalized_country.upcase)
  }

  def full_name
    "#{first_name} #{last_name}"
  end

  def full_address
    [
      address,
      "#{zip_code} #{city}",
      country
    ].join("\n")
  end

  def pennylane_customer_snapshot
    {
      first_name:,
      last_name:,
      phone: phone_number,
      emails: [email],
      billing_language: 'fr_FR',
      payment_conditions: 'upon_receipt',
      billing_address: pennylane_billing_address
    }
  end

  def invalid_email_provider?
    INVALID_EMAIL_PROVIDERS.any? { |provider| email.ends_with?(provider) }
  end

  private

  def pennylane_billing_address
    {
      address:,
      postal_code: zip_code,
      city:,
      country_alpha2: country
    }
  end

  def email_confirmation_required?
    new_record? && email.present? && email_confirmation.present?
  end

  def valid_email_provider
    errors.add(:email, :invalid_provider) if invalid_email_provider?
  end
end
