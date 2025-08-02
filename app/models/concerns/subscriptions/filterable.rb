# frozen_string_literal: true

module Subscriptions
  module Filterable
    extend ActiveSupport::Concern

    included do
      scope :search_and_filter, lambda { |attributes|
        filter_by_status(attributes[:status])
          .filter_by_level(attributes[:level])
          .filter_by_year(attributes[:year])
          .filter_by_course_ids(attributes[:course_ids])
          .filter_by_camp_id(attributes[:camp_id])
      }

      scope :filter_by_status, ->(status) { status.present? ? where(status:) : all }
      scope :filter_by_level, ->(level) { level.present? ? joins(:member).where(members: { level: }) : all }
      scope :filter_by_year, ->(year) { where(year: year.presence || Subscription.current_year) }
      scope :filter_by_course_ids, lambda { |course_ids|
        course_ids&.compact_blank.present? ? where(id: left_joins(courses_subscriptions: :course).where(courses_subscriptions: { course_id: course_ids })) : all
      }
      scope :filter_by_camp_id, lambda { |camp_id|
        camp_id.present? ? where(id: left_joins(camps_subscription: :camp).where(camps_subscription: { camp_id: })) : all
      }
    end
  end
end
