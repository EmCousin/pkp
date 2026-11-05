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
      @course_unavailability_period = Current.platform.course_unavailability_periods.new(period_attributes_from_query)
    end

    def edit
      @course_unavailability_period.assign_attributes(period_attributes_from_query)
    end

    def create
      @course_unavailability_period = Current.platform.course_unavailability_periods.new(course_unavailability_period_params)
      respond_to_persistence(persistence_outcome, :new)
    end

    def update
      outcome = nil
      CourseUnavailabilityPeriod.transaction do
        @course_unavailability_period.assign_attributes(course_unavailability_period_params)
        outcome = persistence_outcome
        raise ActiveRecord::Rollback unless outcome == :saved
      end
      respond_to_persistence(outcome, :edit)
    rescue ActiveRecord::RecordNotSaved
      @course_unavailability_period.errors.add(:courses, :wrong_platform)
      respond_to_persistence(:invalid, :edit)
    end

    def destroy
      @course_unavailability_period.destroy
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
      params.expect(course_unavailability_period: [:starts_on, :ends_on, :conflict_confirmation, { course_ids: [] }])
    end

    def period_attributes_from_query
      return {} unless params[:course_unavailability_period]

      course_unavailability_period_params
    end

    def persistence_outcome
      return :invalid unless @course_unavailability_period.valid?

      @conflicting_discovery_sessions = @course_unavailability_period.conflicting_discovery_sessions.to_a
      return :confirmation_required if @conflicting_discovery_sessions.any? &&
                                       !@course_unavailability_period.conflict_confirmation?

      @course_unavailability_period.save ? :saved : :invalid
    end

    def respond_to_persistence(outcome, form_action)
      case outcome
      when :saved
        redirect_to [:admin, @course_unavailability_period], notice: t('.success'), status: :see_other
      when :confirmation_required
        render :confirm, status: :unprocessable_content
      else
        render form_action, status: :unprocessable_content
      end
    end
  end
end
