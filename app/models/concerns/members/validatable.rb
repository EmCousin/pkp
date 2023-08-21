# frozen_string_literal: true

module Members
  module Validatable
    extend ActiveSupport::Concern

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

    def self.max_birthdate
      99.years.ago
    end

    def self.min_birthdate
      6.years.ago
    end

    included do
      validates :first_name, presence: true
      validates :last_name, presence: true
      validates :birthdate, presence: true, inclusion: { in: Members::Validatable.max_birthdate..Members::Validatable.min_birthdate, on: :create }
      validates :contact_name, presence: true
      validates :contact_phone_number, presence: true, phone: true
      validates :contact_relationship, presence: true, inclusion: { in: CONTACTS }
      validates :avatar, presence: true
      validates :avatar, blob: { content_type: :image }
    end
  end
end
