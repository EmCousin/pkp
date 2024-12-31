# frozen_string_literal: true

module Coach
  class CoursesController < BaseController
    def index
      @courses = Course.featuring_attendance_sheet.order(:weekday, :created_at)
    end
  end
end
