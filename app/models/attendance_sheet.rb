# frozen_string_literal: true

class AttendanceSheet < ApplicationRecord
  belongs_to :course
  has_one :platform, through: :course
  has_many :attendance_records, dependent: :destroy

  validates :date, presence: true, uniqueness: { scope: :course_id }
  validate :course_platform_cannot_change, on: :update, if: :will_save_change_to_course_id?
  validate :course_cannot_change_with_records, if: :will_save_change_to_course_id?

  class << self
    def find_or_create_for_regular_course(course, date = Date.current)
      course.with_lock { find_or_create_regular_sheet(course, date) }
    end

    def find_or_create_for_discovery_session(discovery_session)
      course = discovery_session.course
      sheet = find_or_create_by!(course:, date: discovery_session.occurrence_date)

      populate_records(sheet, course)
    end

    private

    def find_or_create_regular_sheet(course, date)
      sheet = find_by(course:, date:)
      return populate_records(sheet, course) if sheet
      return unavailable_sheet(course, date) if course.unavailable_on?(date)

      populate_records(create!(course:, date:), course)
    end

    def unavailable_sheet(course, date)
      new(course:, date:).tap { |sheet| sheet.errors.add(:date, :unavailable) }
    end

    def populate_records(sheet, course)
      create_attendance_records(sheet, course)

      sheet
    end

    def create_attendance_records(sheet, course)
      member_ids = course.subscriptions.confirmed.filter_by_year(Subscription.current_year(sheet.date)).pluck(:member_id)
      member_ids |= DiscoveryRegistration.confirmed
                                         .where(discovery_session: course.discovery_sessions.on_date(sheet.date))
                                         .pluck(:member_id)

      AttendanceRecord.upsert_all( # rubocop:disable Rails/SkipsModelValidations
        member_ids.map { |member_id| { attendance_sheet_id: sheet.id, member_id: } },
        unique_by: %i[attendance_sheet_id member_id]
      )
    end
  end

  private

  def course_cannot_change_with_records
    return unless persisted? && attendance_records.exists?

    errors.add(:course, :locked)
  end

  def course_platform_cannot_change
    previous_platform_id = Course.joins(:category).where(id: course_id_in_database).pick('categories.platform_id')
    errors.add(:course, :platform_locked) unless previous_platform_id == course&.platform&.id
  end
end
