# frozen_string_literal: true

class Course < ApplicationRecord
  VACATION_MONTHS = (7..8).to_a.freeze
  ALUMNI_MONTHS = VACATION_MONTHS[-1..-1].freeze

  include Courses::Validatable
  include Courses::Available

  belongs_to :category
  has_many :courses_subscriptions, dependent: :destroy
  has_many :subscriptions, through: :courses_subscriptions
  has_many :members, through: :subscriptions

  enum weekday: { lundi: 1, mardi: 2, mercredi: 3, jeudi: 4, vendredi: 5, samedi: 6, dimanche: 7 }
end
