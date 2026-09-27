# frozen_string_literal: true

module Courses
  module Available
    extend ActiveSupport::Concern

    included do
      scope :active, -> { where(active: true) }
    end

    class_methods do
      def available(year = Subscription.current_year)
        return none if year > Subscription.current_year

        active.where(id: with_courses_available(year))
      end

      def with_courses_available(year)
        includes(:subscriptions).select do |course|
          course.available?(year)
        end
      end
    end

    def available?(year = Subscription.current_year)
      availability(year).positive?
    end

    def availability(year = Subscription.current_year)
      capacity - active_subscriptions(year).size
    end

    def available_discovery_dates(excluding: nil)
      return [] unless active? && discovery_enabled?

      first_date = next_discovery_date
      return [] unless first_date

      dates = first_date.step(discovery_season_end, 7).to_a
      dates.delete(excluding)
      sessions_by_date = discovery_sessions.starting_from(Time.current).index_by(&:occurrence_date)
      dates.select { |date| discovery_date_open?(sessions_by_date[date]) }
    end

    private

    def active_subscriptions(year)
      subscriptions.reject do |subscription|
        subscription.archived? || subscription.year != year
      end
    end

    def discovery_date_open?(session)
      session.nil? || (session.open_for_registration? && !session.fully_booked?)
    end
  end
end
