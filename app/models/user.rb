# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

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

  has_many :subscriptions, foreign_key: :member_id, dependent: :destroy
  has_many :courses, through: :subscriptions

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :birthdate, presence: true, inclusion: { in: (99.years.ago)..(8.years.ago), on: :create }
  validates :phone_number, presence: true, phone: true
  validates :address, presence: true
  validates :zip_code, presence: true
  validates :city, presence: true
  validates :country, presence: true
  validates :contact_name, presence: true
  validates :contact_phone_number, presence: true, phone: true
  validates :contact_relationship, presence: true, inclusion: { in: CONTACTS }
  validates :agreed_to_publicity_right, presence: true
  validates :avatar, presence: true

  has_one_attached :avatar

  def full_name
    "#{first_name} #{last_name}".downcase.titleize
  end
end
