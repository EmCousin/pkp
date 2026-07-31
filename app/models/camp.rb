# frozen_string_literal: true

class Camp < ApplicationRecord
  has_rich_text :description
  has_one_attached :cover_picture

  validates :title, :capacity, :starts_at, :ends_at, :price, :external_price, presence: true
  validates :capacity, numericality: { greater_than_or_equal_to: 1, only_integer: true }
  validates :price, :external_price, numericality: { greater_than: 0 }
  validates :ends_at, comparison: {
    greater_than_or_equal_to: :starts_at,
    message: lambda { |object, _options|
      I18n.t(
        'activerecord.errors.models.camp.attributes.ends_at.later_than_or_equal_to',
        date: I18n.l(object.starts_at, format: :short)
      )
    },
    if: :ends_at?
  }
  validate :registration_year_must_match

  has_many :camps_subscriptions, dependent: :restrict_with_error
  has_many :subscriptions, through: :camps_subscriptions
  has_many :members, through: :subscriptions

  scope :active, -> { where(active: true) }
  scope :upcoming, -> { where(starts_at: Date.current..) }
  scope :available, -> { active.upcoming }

  def closed?
    !open?
  end

  def duration_days
    (ends_at - starts_at).to_i + 1
  end

  def available_slots
    capacity - occupied_slots
  end

  def occupied_slots
    subscriptions.not_archived.count
  end

  def fully_booked?
    available_slots <= 0
  end

  def internal_for?(member)
    member.annual_subscription_for(year).present?
  end

  def accessible_to?(member)
    internal_for?(member) || open_to_externals?
  end

  def price_for(member)
    internal_for?(member) ? price : external_price
  end

  def year
    Subscription.current_year(starts_at)
  end

  class << self
    def struct_by_year
      hash = order(created_at: :desc).group_by { |camp| Subscription.current_year(camp.starts_at) }
      hash.map do |year, camps|
        struct = Struct.new(:year, :camps)
        struct.new(year, camps)
      end
    end
  end

  private

  def registration_year_must_match
    return unless starts_at && subscriptions.where.not(year: year).exists?

    errors.add(:starts_at, :event_year_locked)
  end
end
