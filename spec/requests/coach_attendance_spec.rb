require 'rails_helper'

describe 'Coach attendance', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:coach) { create(:user, coach: true, phone_number: '+33612345678') }
  let(:course) { create(:course) }
  let(:member_a) { create(:member) }
  let(:member_b) { create(:member) }

  before do
    create(:subscription, status: :confirmed, courses: [course], member: member_a)
    create(:subscription, status: :confirmed, courses: [course], member: member_b)
    sign_in coach
  end

  it 'updates only the targeted attendance record' do
    sheet = AttendanceSheet.find_or_create_for_course(course)
    record_a = sheet.attendance_records.find_by(member: member_a)
    record_b = sheet.attendance_records.find_by(member: member_b)
    record_a.update!(status: :excused)

    patch coach_attendance_sheet_attendance_record_path(sheet, record_b),
          params: { attendance_record: { status: 'absent' } }

    expect(response).to redirect_to(coach_attendance_sheet_path(sheet))
    expect(record_b.reload.status).to eq('absent')
    expect(record_a.reload.status).to eq('excused')
  end
end
