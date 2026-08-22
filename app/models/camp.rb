# frozen_string_literal: true

class Camp < ApplicationRecord
  include Events::CapacityLimited

  belongs_to :platform

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
  validate :platform_cannot_change, on: :update, if: :will_save_change_to_platform_id?

  has_many :camps_subscriptions, dependent: :restrict_with_error
  has_many :subscriptions, through: :camps_subscriptions
  has_many :members, through: :subscriptions

  scope :active, -> { where(active: true) }
  scope :visible, -> { where(active: true).or(where(visible_to_externals: true)) }
  scope :upcoming, -> { where(starts_at: Date.current..) }
  scope :available, -> { active.upcoming }
  scope :search_by_title, lambda { |query|
    query.present? ? where('LOWER(camps.title) LIKE ?', "%#{sanitize_sql_like(query.downcase)}%") : all
  }
  scope :filter_by_flag, ->(attribute, value) { value.present? ? where(attribute => value) : all }
  scope :filter_by_year, lambda { |year|
    year = Integer(year, exception: false)
    next all unless year

    where(starts_at: Course.vacation_start(year).to_date...Course.vacation_start(year + 1).to_date)
  }
  scope :search_and_filter, lambda { |attributes|
    search_by_title(attributes[:q])
      .filter_by_flag(:active, attributes[:active])
      .filter_by_flag(:visible_to_externals, attributes[:visible_to_externals])
      .filter_by_flag(:open, attributes[:open])
      .filter_by_flag(:open_to_externals, attributes[:open_to_externals])
      .filter_by_year(attributes[:year])
  }

  def closed?
    !open? && !open_to_externals?
  end

  def duration_days
    (ends_at - starts_at).to_i + 1
  end

  def internal_for?(member)
    member.annual_subscription_for(year).present?
  end

  def open_for?(member)
    internal_for?(member) ? open? : open_to_externals?
  end

  def visible_for?(member)
    internal_for?(member) ? active? : visible_to_externals?
  end

  def visible_to?(members)
    members = Array(members)
    return visible_to_externals? if members.empty?

    members.any? { |member| visible_for?(member) }
  end

  def price_for(member)
    internal_for?(member) ? price : external_price
  end

  def year
    Subscription.current_year(starts_at)
  end

  class << self
    def struct_by_year(scope = all)
      hash = scope.order(created_at: :desc).group_by { |camp| Subscription.current_year(camp.starts_at) }
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

  def platform_cannot_change
    errors.add(:platform, :locked)
  end
end
