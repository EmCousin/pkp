# frozen_string_literal: true

module Admin
  class CourseUnavailabilityPeriodsController < BaseController
    before_action :set_course_unavailability_period, only: %i[show edit update destroy]
    before_action :set_courses, only: %i[new create edit update]

    def index
      periods = Current.platform.course_unavailability_periods
      @course_unavailability_periods = periods.includes(:courses).order(starts_on: :desc, created_at: :desc)
    end

    def show; end

    def new
      @course_unavailability_period = Current.platform.course_unavailability_periods.new
    end

    def edit; end

    def create
      @course_unavailability_period = Current.platform.course_unavailability_periods.new(course_unavailability_period_params)
      if @course_unavailability_period.save_with_course_locks
        redirect_to [:admin, @course_unavailability_period], notice: t('.success'), status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @course_unavailability_period.update_with_course_locks(course_unavailability_period_params)
        redirect_to [:admin, @course_unavailability_period], notice: t('.success'), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @course_unavailability_period.destroy_with_course_locks
      redirect_to admin_course_unavailability_periods_path, notice: t('.success'), status: :see_other
    end

    private

    def set_course_unavailability_period
      @course_unavailability_period = Current.platform.course_unavailability_periods.find(params.expect(:id))
    end

    def set_courses
      @courses = Current.platform.courses.includes(:category).order('categories.title', :weekday, :title)
    end

    def course_unavailability_period_params
      params.expect(course_unavailability_period: [:starts_on, :ends_on, { course_ids: [] }])
    end
  end
end
