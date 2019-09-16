class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  CONTACTS = ['Père', 'Mère', 'Tuteur / Tutrice', 'Conjoint(e)', 'Frère', 'Sœur', 'Grand-père', 'Grand-mère', 'Oncle', 'Tante', 'Cousin(e)', 'Ami(e)', 'Autre'].freeze
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :birthdate, presence: true
  validates :phone_number, presence: true
  validates :address, presence: true
  validates :zip_code, presence: true
  validates :city, presence: true
  validates :country, presence: true
  validates :contact_name, presence: true
  validates :contact_phonering, presence: true
  validates :contact_relatring, presence: true, inclusion: { in: CONTACTS }
  validates :agreed_to_pub, :boolean, presence: true
  validates :avatar, presence: true
end
