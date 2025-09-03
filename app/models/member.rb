# frozen_string_literal: true

class Member < ApplicationRecord
  include ConditionalPagination
  include Members::Available
  include Members::Searchable

  MAJORITY_AGE = 18

  CONTACTS = [
    'Père',
    'Mère',
    'Tuteur / Tutrice',
    'Conjoint·e',
    'Frère',
    'Sœur',
    'Grand-père',
    'Grand-mère',
    'Oncle',
    'Tante',
    'Cousin·e',
    'Ami·e',
    'Autre'
  ].freeze

  belongs_to :user
  accepts_nested_attributes_for :user

  has_many :contacts, through: :user
  has_many :subscriptions, dependent: :destroy
  has_one :current_subscription, -> { where(year: Subscription.current_year) }, class_name: 'Subscription', inverse_of: :member, dependent: :destroy
  has_many :courses, through: :subscriptions
  has_many :camps, through: :subscriptions
  has_many :attendance_records, dependent: :destroy
  has_many :attendance_sheets, through: :attendance_records

  has_one_attached :avatar do |attachable|
    attachable.variant :mini, resize: '80x80'
  end

  enum :level, white: 'white', yellow: 'yellow', green: 'green', red: 'red'

  validates :first_name, :last_name, :contact_name, :avatar, presence: true
  validates :birthdate, presence: true, inclusion: { in: (99.years.ago)..(6.years.ago), on: :create }
  validates :contact_phone_number, presence: true, phone: true
  validates :contact_relationship, presence: true, inclusion: { in: CONTACTS }

  delegate :email, :phone_number, :address, :zip_code, :city, :country, :full_address,
           to: :user

  normalizes :first_name, with: ->(first_name) { first_name.strip.downcase.titleize }
  normalizes :last_name, with: ->(last_name) { last_name.strip.downcase.titleize }

  def full_name
    "#{first_name.strip.downcase.titleize} #{last_name.strip.downcase.titleize}"
  end

  def age(year = Time.current.year)
    year - birthdate.year
  end

  def minor?(year = Time.current.year)
    age(year) < MAJORITY_AGE
  end

  def attendance_records_for(course)
    if attendance_records.loaded?
      attendance_records.select { |record| record.course == course }
    else
      attendance_records.joins(:attendance_sheet).where(attendance_sheets: { course: })
    end
  end

  def can_subscribe?(camp)
    return false if camp.fully_booked?
    return false unless current_subscription&.confirmed?
    return false if camps.include?(camp)

    true
  end
end
