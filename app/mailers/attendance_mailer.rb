# frozen_string_literal: true

class AttendanceMailer < ApplicationMailer
  def consecutive_absences(member, course)
    @member = member
    @course = course

    mail(
      to: @member.email,
      subject: t('.subject', course_title: @course.title)
    )
  end
end
