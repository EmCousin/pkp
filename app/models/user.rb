# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable

  include DeviseExtensions::Validatable

  has_many :members, dependent: :destroy
  has_many :subscriptions, through: :members
  has_many :courses, through: :subscriptions

  with_options on: :account_setup, if: ->(user) { user.confirmed? && !user.confirmed_at_changed? } do |user|
    user.validates :phone_number, presence: true, phone: true
    user.validates :address, presence: true
    user.validates :zip_code, presence: true
    user.validates :city, presence: true
    user.validates :country, presence: true
  end

  after_create :create_stripe_customer_id

  private

  def create_stripe_customer_id
    Stripe::CreateCustomerJob.perform_later(self)
  end
end
