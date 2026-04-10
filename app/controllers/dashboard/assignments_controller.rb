# frozen_string_literal: true

module Dashboard
  class AssignmentsController < DashboardController
    def show
      @year = Time.current.year
      @courses = Course.includes(:category).where(active: true).order(:title)
      @assignments = Assignment.includes(:coach, :course).where(year: @year)
    end
  end
end
