class Course < ApplicationRecord
  CATEGORIES = ['Adulte', 'Adulte Féminin', 'Adolescent (13 - 15 ans)', 'Adolescent (10 - 12 ans)', 'Kidz (6 - 9 ans)'].freeze

  has_many :courses_subscriptions, dependent: :destroy
  has_many :subscriptions, through: :courses_subscriptions
  has_many :members, through: :subscriptions

  validates :title, :capacity, :category, presence: true
  validates :capacity, numericality: { greater_than_or_equal_to: 1, only_integer: true }
  validates :category, inclusion: { in: CATEGORIES }

  enum weekday: { lundi: 1, mardi: 2, mercredi: 3, jeudi: 4, vendredi: 5, samedi: 6, dimanche: 7 }
end
