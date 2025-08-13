# frozen_string_literal: true

class Pricing < ApplicationRecord
  belongs_to :category

  # Virtual attribute to edit prices as a comma-separated list in forms
  attribute :prices_string, :string

  before_validation :normalize_prices_from_string

  validates :name, presence: true
  validates :starts_at, :ends_at, presence: true
  validates :ends_at, comparison: { greater_than: :starts_at, if: %i[starts_at? ends_at?] }
  validate :prices_presence_and_numericality

  scope :current, -> { covering(Date.current) }
  scope :for_category, ->(category) { where(category_id: category.is_a?(Category) ? category.id : category) }
  scope :covering, ->(date) { where(starts_at: ..date, ends_at: date..) }
  scope :covering_year, ->(year) { where(starts_at: Date.new(year - 1, 8, 1).., ends_at: ..Date.new(year, 7, 31)) }

  def prices
    # Ensure we always expose an array of BigDecimals
    Array(self[:prices]).map(&:to_d)
  end

  private

  def normalize_prices_from_string
    return if prices_string.blank?

    parsed = prices_string.split(',').map(&:strip).compact_blank
    self[:prices] = parsed.map { |v| BigDecimal(v) }
  rescue ArgumentError
    errors.add(:prices, :invalid)
  end

  def prices_presence_and_numericality
    raw = self[:prices]
    values = raw.is_a?(Hash) ? [] : Array(raw)
    errors.add(:prices, :blank) if values.blank?
    return if values.blank?

    return if values.all? { |v| v.is_a?(Numeric) || v.to_s.match?(/\A-?\d+(?:[\.,]\d+)?\z/) }

    errors.add(:prices, :not_a_number)
  end
end
