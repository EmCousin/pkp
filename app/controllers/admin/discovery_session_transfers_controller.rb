# frozen_string_literal: true

module Admin
  class DiscoverySessionTransfersController < BaseController
    before_action :set_subscription
    before_action :set_available_dates

    def new; end

    def create
      occurs_on = Date.iso8601(transfer_params[:occurs_on].to_s)
      return render_invalid_date unless @available_dates.include?(occurs_on)

      target_session = DiscoverySession.find_or_create_for_course!(course: @course, occurs_on:)
      if @subscription.transfer_to(target_session)
        redirect_to [:admin, @subscription], notice: t('.success'), status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    rescue Date::Error, ActiveRecord::RecordInvalid
      render_invalid_date
    end

    private

    def set_subscription
      @subscription = Current.platform.subscriptions
                             .where(type: DiscoveryRegistration.sti_name)
                             .find(params.expect(:subscription_id))
      @course = @subscription.discovery_session.course
    end

    def set_available_dates
      first_date = @course.next_discovery_date if @course.active? && @course.discovery_enabled?
      @available_dates = first_date ? first_date.step(@course.discovery_season_end, 7).to_a : []
      @available_dates.delete(@subscription.discovery_session.occurrence_date)
      @sessions_by_date = @course.discovery_sessions.starting_from(Time.current).index_by(&:occurrence_date)
      @available_dates.select! { |date| session_available_on?(date) }
    end

    def session_available_on?(date)
      session = @sessions_by_date[date]
      session.nil? || (session.open_for_registration? && !session.fully_booked?)
    end

    def transfer_params
      params.expect(discovery_session_transfer: [:occurs_on])
    end

    def render_invalid_date
      @subscription.errors.add(:discovery_session, :unavailable)
      render :new, status: :unprocessable_content
    end
  end
end
