# frozen_string_literal: true

class AttendanceRecord < ApplicationRecord
  belongs_to :attendance_sheet
  has_one :course, through: :attendance_sheet
  belongs_to :member
  has_one :user, through: :member

  enum :status, { present: 'present', absent: 'absent', excused: 'excused' }

  validates :member, uniqueness: { scope: :attendance_sheet_id }

  after_save :check_consecutive_absences, if: :absent?

  scope :recent, -> { order(created_at: :desc).limit(3) }

  STATUS_STYLES = {
    present: {
      emoji: '✅',
      label: I18n.t('activerecord.attributes.attendance_record.statuses.present'),
      color: 'bg-green-100 text-green-800 border-green-300 hover:bg-green-200'
    },
    excused: {
      emoji: '🙏',
      label: I18n.t('activerecord.attributes.attendance_record.statuses.excused'),
      color: 'bg-yellow-100 text-yellow-800 border-yellow-300 hover:bg-yellow-200'
    },
    absent: {
      emoji: '❌',
      label: I18n.t('activerecord.attributes.attendance_record.statuses.absent'),
      color: 'bg-red-100 text-red-800 border-red-300 hover:bg-red-200'
    }
  }.freeze

  def status_style
    STATUS_STYLES[status.to_sym] || {
      emoji: '•',
      label: I18n.t('activerecord.attributes.attendance_record.statuses.unknown', default: 'Inconnu'),
      color: 'bg-gray-100 text-gray-800 border-gray-300'
    }
  end

  private

  def check_consecutive_absences
    recent_records = member.attendance_records
                           .joins(:attendance_sheet)
                           .where(attendance_sheets: { course_id: attendance_sheet.course_id })
                           .recent

    return unless recent_records.count == 3 && recent_records.all?(&:absent?)

    AttendanceMailer.consecutive_absences(member, attendance_sheet.course).deliver_now
  end
end
