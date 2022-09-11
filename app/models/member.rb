# frozen_string_literal: true

class Member < ApplicationRecord
  include Members::Validatable
  include Members::Available
  include Members::Searchable
  include Members::Decoratable

  belongs_to :user
  accepts_nested_attributes_for :user

  has_many :contacts, through: :user
  has_many :subscriptions, dependent: :destroy
  has_many :courses, through: :subscriptions

  has_one_attached :avatar do |attachable|
    attachable.variant :mini, resize: '80x80'
  end
end
