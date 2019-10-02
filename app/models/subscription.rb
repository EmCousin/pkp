class Subscription < ApplicationRecord
  belongs_to :member, class_name: 'User'
  has_many :courses_subscriptions, dependent: :destroy
  has_many :courses, through: :courses_subscriptions

  validates :year, numericality: { only_integer: true }, presence: true
  validates :fee, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :member_id, uniqueness: { scope: :year }
  validate :year_is_current, on: :create
  validate :at_least_one_is_checked

  private

  def year_is_current
    errors.add(:year, :must_be_current) unless year == Time.now.year
  end

  def at_least_one_is_checked
    errors.add(:courses, :must_exist) if course_ids.empty?
  end
end