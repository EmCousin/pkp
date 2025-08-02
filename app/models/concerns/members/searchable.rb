# frozen_string_literal: true

module Members
  module Searchable
    extend ActiveSupport::Concern

    included do # rubocop:disable Metrics/BlockLength
      scope(:search_and_filter, lambda do |attributes|
        search(attributes[:q])
          .filter_by_level(attributes[:level])
          .filter_by_subscription_year(attributes[:subscription_year])
          .filter_by_course_ids(attributes[:course_ids])
          .filter_by_camp_ids(attributes[:camp_ids])
      end)

      scope(:search, lambda do |query|
        return all if query.blank?

        joins(:user).where(
          'LOWER(first_name) LIKE :search
          OR LOWER(last_name) LIKE :search
          OR LOWER(users.email) LIKE :search
          OR users.phone_number LIKE :search',
          search: "%#{query.downcase}%"
        )
      end)

      scope(:filter_by_level, ->(level) { level.present? ? where(level:) : all })

      scope(:filter_by_subscription_year, ->(year) { year.present? ? left_joins(:subscriptions).rewhere(subscriptions: { year: }) : all })

      scope(:filter_by_course_ids, lambda do |course_ids|
        return all if course_ids&.compact_blank.blank?

        where(id: left_joins(subscriptions: :courses_subscriptions).where(courses_subscriptions: { course_id: course_ids }))
      end)

      scope(:filter_by_camp_ids, lambda do |camp_ids|
        return all if camp_ids&.compact_blank.blank?

        where(id: left_joins(subscriptions: :camps_subscription).where(camps_subscriptions: { camp_id: camp_ids }))
      end)
    end
  end
end
