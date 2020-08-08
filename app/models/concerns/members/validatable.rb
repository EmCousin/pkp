# frozen_string_literal: true

module Members
  module Validatable
    extend ActiveSupport::Concern

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

    included do
      validates :first_name, presence: true
      validates :last_name, presence: true
      validates :birthdate, presence: true, inclusion: { in: (99.years.ago)..(8.years.ago), on: :create }
      validates :contact_name, presence: true
      validates :contact_phone_number, presence: true, phone: true
      validates :contact_relationship, presence: true, inclusion: { in: CONTACTS }
      validates :agreed_to_advertising_right, presence: true
      validates :avatar, presence: true
    end
  end
end
