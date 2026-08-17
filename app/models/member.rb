# frozen_string_literal: true

class Member < ApplicationRecord
  include ConditionalPagination
  include Members::Available
  include Members::Searchable
  include Members::SubscriptionForm
  include Subscriptions::ProtectsFinalizedRegistrations

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
  belongs_to :platform
  accepts_nested_attributes_for :user

  has_many :contacts, through: :user
  has_many :subscriptions, dependent: :destroy
  has_many :courses, through: :subscriptions
  has_many :camps, through: :subscriptions
  has_many :discovery_sessions, through: :subscriptions
  has_many :attendance_records, dependent: :destroy
  has_many :attendance_sheets, through: :attendance_records

  has_one_attached :avatar do |attachable|
    attachable.variant :mini, resize: '80x80'
  end

  enum :level, white: 'white', yellow: 'yellow', green: 'green', red: 'red'

  validates :first_name, :last_name, :contact_name, :avatar, presence: true
  validates :birthdate, presence: true
  validates :birthdate, inclusion: { in: ->(_) { 99.years.ago.to_date..6.years.ago.to_date } }, on: :create, allow_blank: true
  validates :contact_phone_number, presence: true, phone: true
  validates :contact_relationship, presence: true, inclusion: { in: CONTACTS }
  validate :platform_cannot_change_with_activity, if: :will_save_change_to_platform_id?

  delegate :email, :phone_number, :address, :zip_code, :city, :country, :full_address,
           to: :user

  normalizes :first_name, with: ->(first_name) { first_name.strip.downcase.titleize }
  normalizes :last_name, with: ->(last_name) { last_name.strip.downcase.titleize }

  def full_name
    "#{first_name.strip.downcase.titleize} #{last_name.strip.downcase.titleize}"
  end

  def admin_label
    "#{user.email} - #{full_name}"
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

  def annual_subscription_for(year = Subscription.current_year)
    subscriptions.where(type: AnnualSubscription.sti_name)
                 .confirmed
                 .find_by(year:, parent_subscription_id: nil)
  end

  alias current_subscription annual_subscription_for

  def can_subscribe?(camp)
    return false unless camp.platform == platform
    return false if camp.closed?
    return false if camp.fully_booked?
    return false unless camp.accessible_to?(self)
    return false if camps.exists?(camp.id)

    true
  end

  def can_subscribe_to_discovery?(discovery_session)
    discovery_session.platform == platform &&
      discovery_session.open_for_registration? &&
      !discovery_session.fully_booked? &&
      discovery_session.course.category.suitable_for_age?(age(discovery_session.year)) &&
      !discovery_sessions.exists?(discovery_session.id)
  end

  private

  def platform_cannot_change_with_activity
    return unless persisted? && (subscriptions.exists? || attendance_records.exists?)

    errors.add(:platform, :locked)
  end
end
