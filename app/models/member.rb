# frozen_string_literal: true

class Member < ApplicationRecord
  include Members::Available
  include Members::Searchable

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
  has_one :current_subscription, -> { find_by(year: Subscription.current_year) }, class_name: 'Subscription', inverse_of: :member, dependent: :destroy
  has_many :courses, through: :subscriptions
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

  def full_name
    "#{first_name} #{last_name}".downcase.titleize
  end

  def age(year = Time.current.year)
    year - birthdate.year
  end

  def attendance_records_for(course)
    if attendance_records.loaded?
      attendance_records.select { |record| record.course == course }
    else
      attendance_records.joins(:attendance_sheet).where(attendance_sheets: { course: })
    end
  end
end
