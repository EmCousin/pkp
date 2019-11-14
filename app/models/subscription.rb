class Subscription < ApplicationRecord
  belongs_to :member, class_name: 'User'
  has_many :courses_subscriptions, dependent: :destroy
  has_many :courses, through: :courses_subscriptions

  validates :year, numericality: { only_integer: true }, presence: true
  validates :fee, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :member_id, uniqueness: { scope: :year }
  validate :year_is_current, on: :create
  validate :has_at_least_one_course
  validate :has_maximum_three_courses
  validate :courses_are_of_the_same_category


  def compute_fee
    courses_count = courses.count
    category = courses.first.category

    if courses_count == 1 && category == 'Adulte'
      175
    elsif courses_count == 2 && category == 'Adulte'
      285
    elsif courses_count == 3 && category == 'Adulte'
      330
    elsif courses_count == 1 && category == 'Adolescent (10 - 12 ans)'
      175
    elsif courses_count == 1 && category == 'Adolescent (13 - 15 ans)'
      175
    elsif courses_count == 2 && category == 'Adolescent (10 - 12 ans)'
      300
    elsif courses_count == 2 && category == 'Adolescent (13 - 15 ans)'
      300
    elsif courses_count == 1 && category == 'Kidz (6 - 9 ans)'
      175
    end
  end

  private

  def year_is_current
    errors.add(:year, :must_be_current) unless year == Time.now.year
  end

  def has_at_least_one_course
    errors.add(:courses, :must_exist) if course_ids.empty?
  end

  def has_maximum_three_courses
    errors.add(:courses, :limit_exceeded) if course_ids.count > 3
  end

  def courses_are_of_the_same_category
    unique_category = true
    previous_category = nil
    courses.each do |course|
      if previous_category == nil 
        previous_category = course.category
      else
        if course.category != previous_category
          unique_category = false
          break
        end
      end
    end  
    errors.add(:courses, :unique_category) unless unique_category
  end
end
