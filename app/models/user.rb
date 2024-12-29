# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :lockable,
         :timeoutable

  include Users::Validatable
  include Users::AdminNotifiable
  include Users::Chargeable

  has_many :contacts, dependent: :destroy
  accepts_nested_attributes_for :contacts, reject_if: :all_blank, allow_destroy: true

  has_many :members, dependent: :destroy
  has_many :subscriptions, through: :members
  has_many :courses, through: :subscriptions

  def full_address
    [
      address,
      "#{zip_code} #{city}",
      country
    ].join("\n")
  end
end
