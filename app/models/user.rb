# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :timeoutable

  include DeviseExtensions::Validatable

  has_many :members, dependent: :destroy
  has_many :subscriptions, through: :members
  has_many :courses, through: :subscriptions

  validates :terms_of_service, acceptance: true

  with_options on: :account_setup, if: ->(_user) { true } do |user| # user.confirmed? && !user.confirmed_at_changed?
    user.validates :phone_number, presence: true, phone: true
    user.validates :address, presence: true
    user.validates :zip_code, presence: true
    user.validates :city, presence: true
    user.validates :country, presence: true
  end

  after_create :create_stripe_customer_id

  before_update :notify_admins, if: :email_changed?

  private

  def create_stripe_customer_id
    Stripe::CreateCustomerJob.perform_later(self)
  end

  def notify_admins
    AdminMailer.email_changed(email_was, email).deliver_later
  end
end
