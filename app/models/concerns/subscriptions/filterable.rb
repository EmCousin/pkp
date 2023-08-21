# frozen_string_literal: true

module Subscriptions
  module Filterable
    extend ActiveSupport::Concern

    included do
      scope :filter_by_status, ->(status) { status.present? ? where(status:) : all }
      scope :filter_by_level, ->(level) { level.present? ? joins(:member).where(members: { level: }) : all }
      scope :filter_by_year, ->(year) { where(year: year.presence || Subscription.current_year) }
    end
  end
end
