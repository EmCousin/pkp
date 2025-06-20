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
  has_one :current_subscription, -> { find_by(year: Subscription.current_year) }, class_name: 'Subscription', inverse_of: :member, dependent: :destroy
  has_many :courses, through: :subscriptions
  has_many :attendance_records, dependent: :destroy
  has_many :attendance_sheets, through: :attendance_records

  has_one_attached :avatar do |attachable|
    attachable.variant :mini, resize: '80x80'
  end

  enum :level, white: 'white', yellow: 'yellow', green: 'green', red: 'red'

  delegate :full_address, to: :user

  def attendance_records_for(course)
    if attendance_records.loaded?
      attendance_records.select { |record| record.course == course }
    else
      attendance_records.joins(:attendance_sheet).where(attendance_sheets: { course: })
    end
  end
end
