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

  has_many :members, dependent: :destroy
  has_many :subscriptions, through: :members
  has_many :courses, through: :subscriptions
end
