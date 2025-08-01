# frozen_string_literal: true

class Camp < ApplicationRecord
  has_rich_text :description
  has_one_attached :cover_picture

  validates :title, :capacity, :starts_at, :ends_at, :price, presence: true
  validates :capacity, numericality: { greater_than_or_equal_to: 1, only_integer: true }
  validates :price, numericality: { greater_than: 0 }
  validates :ends_at, comparison: { greater_than_or_equal_to: :starts_at, message: 'must be greater than or equal to starts_at' }

  has_many :camps_subscriptions, dependent: :destroy
  has_many :subscriptions, through: :camps_subscriptions
  has_many :members, through: :subscriptions

  scope :active, -> { where(active: true) }
  scope :upcoming, -> { where('starts_at >= ?', Date.current) }
  scope :available, -> { active.upcoming }

  def duration_days
    (ends_at - starts_at).to_i + 1
  end

  def available_slots
    capacity - subscriptions.confirmed.count
  end

  def fully_booked?
    available_slots <= 0
  end
end
