# frozen_string_literal: true
class Category < ApplicationRecord
  has_many :courses, dependent: :restrict_with_error

  validates :title, presence: true, uniqueness: true
end
