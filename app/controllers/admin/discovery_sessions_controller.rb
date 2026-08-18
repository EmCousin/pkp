# frozen_string_literal: true

module Admin
  class DiscoverySessionsController < BaseController
    before_action :set_discovery_session, only: %i[show edit update destroy]

    def index
      sessions = Current.platform.discovery_sessions.on_date(search_date)
      @discovery_sessions = sessions.includes(:course, :subscriptions)
                                    .order(starts_at: :desc)
                                    .page(params[:page])
                                    .per(25)
    end

    def show
      @attendance_sheet = AttendanceSheet.find_or_create_for_course(@discovery_session.course, @discovery_session.occurrence_date)
      @attendance_records = @attendance_sheet.attendance_records.includes(member: :avatar_attachment)
    end

    def new
      @discovery_session = DiscoverySession.new
    end

    def edit; end

    def create
      @discovery_session = DiscoverySession.new(discovery_session_params)

      if @discovery_session.save
        redirect_to [:admin, @discovery_session], notice: t('.success'), status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @discovery_session.update(discovery_session_params)
        redirect_to [:admin, @discovery_session], notice: t('.success'), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @discovery_session.destroy
        redirect_to admin_discovery_sessions_path, notice: t('.success'), status: :see_other
      else
        redirect_to admin_discovery_sessions_path, alert: t('.error'), status: :see_other
      end
    end

    private

    def set_discovery_session
      @discovery_session = Current.platform.discovery_sessions.find(params[:id])
    end

    def search_date
      Date.iso8601(params[:date]) if params[:date].present?
    rescue Date::Error
      nil
    end

    def discovery_session_params
      attributes = params.expect(discovery_session: %i[course_id starts_at capacity price active open])
      Current.platform.courses.find(attributes[:course_id]) if attributes[:course_id].present?
      attributes
    end
  end
end
