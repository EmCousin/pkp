# frozen_string_literal: true

module Admin
  class AssignmentsController < BaseController
    def index
      @year = params[:year] || Time.current.year
      @coaches = Member.coaches.order(:last_name, :first_name)
      @courses = Course.includes(:category).where(active: true).order(:title)
      @assignments = Assignment.includes(:coach, :course).where(year: @year)
    end

    def create
      @assignment = Assignment.new(assignment_params)
      if @assignment.save
        redirect_to admin_assignments_path(year: @assignment.year), notice: t(".success")
      else
        redirect_to admin_assignments_path(year: @assignment.year), alert: t(".failure")
      end
    end

    def destroy
      @assignment = Assignment.includes(:coach, :course).find(params[:id])
      @assignment.destroy
      redirect_to admin_assignments_path(year: @assignment.year), notice: t(".success")
    end

    private

    def assignment_params
      params.expect(assignment: [:coach_id, :course_id, :level, :year])
    end
  end
end
