# frozen_string_literal: true

class Member < ApplicationRecord
  CONTACTS = [
    'Père',
    'Mère',
    'Tuteur / Tutrice',
    'Conjoint(e)',
    'Frère',
    'Sœur',
    'Grand-père',
    'Grand-mère',
    'Oncle',
    'Tante',
    'Cousin(e)',
    'Ami(e)',
    'Autre'
  ].freeze

  belongs_to :user
  accepts_nested_attributes_for :user
  has_many :subscriptions, dependent: :destroy
  has_many :courses, through: :subscriptions

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :birthdate, presence: true, inclusion: { in: (99.years.ago)..(8.years.ago), on: :create }
  validates :contact_name, presence: true
  validates :contact_phone_number, presence: true, phone: true
  validates :contact_relationship, presence: true, inclusion: { in: CONTACTS }
  validates :agreed_to_advertising_right, presence: true
  validates :avatar, presence: true

  has_one_attached :avatar

  delegate :email, :phone_number, :address, :zip_code, :city, :country,
           to: :user

  def full_name
    "#{first_name} #{last_name}".downcase.titleize
  end
end
