# frozen_string_literal: true

module Subscriptions
  module Filterable
    extend ActiveSupport::Concern

    included do
      scope :filter_by_status, ->(status) { status.present? ? where(status:) : all }
      scope :filter_by_level, ->(level) { level.present? ? joins(:member).where(members: { level: }) : all }
      scope :filter_by_year, ->(year) { where(year: year.presence || Subscription.current_year) }
      scope :filter_by_course_ids, ->(course_ids) { course_ids&.compact_blank.present? ? where(courses_subscriptions: { course_id: course_ids }) : all }
      scope :filter_by_camp_id, ->(camp_id) { camp_id.present? ? where(camps_subscription: { camp_id: }) : all }
    end
  end
end
