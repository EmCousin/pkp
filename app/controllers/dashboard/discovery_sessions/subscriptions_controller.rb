# frozen_string_literal: true

module Dashboard
  module DiscoverySessions
    class SubscriptionsController < DashboardController
      before_action :set_available_discovery_session, :set_member, :check_open_status, only: :create
      before_action :set_subscription, :check_cancellable, only: :destroy

      def create
        @subscription = DiscoveryRegistration.new(
          member: @member,
          discovery_session: @discovery_session,
          year: @discovery_session.year
        )

        if @discovery_session.with_lock { @subscription.save }
          redirect_to next_completion_step_path(@subscription), status: :see_other
        else
          redirect_back_or_to [:dashboard, @discovery_session], alert: @subscription.errors.full_messages.to_sentence
        end
      end

      def destroy
        if @subscription.destroy
          redirect_to [:dashboard, @discovery_session], notice: t('.success'), status: :see_other
        else
          redirect_to [:dashboard, @discovery_session], alert: t('.error'), status: :unprocessable_content
        end
      end

      private

      def set_available_discovery_session
        @discovery_session = Current.platform.discovery_sessions.available.find(params[:discovery_session_id])
      end

      def set_member
        @member = current_user.members.find_by!(platform: Current.platform, id: params.require(:member_id))
      end

      def set_subscription
        @subscription = current_user.subscriptions
                                    .for_platform(Current.platform)
                                    .where(type: DiscoveryRegistration.sti_name)
                                    .joins(:discovery_session)
                                    .find_by!(id: params[:id], discovery_sessions: { id: params[:discovery_session_id] })
        @discovery_session = @subscription.discovery_session
      end

      def check_open_status
        redirect_to [:dashboard, @discovery_session], alert: t('.closed') unless @discovery_session.open_for_registration?
      end

      def check_cancellable
        return if @subscription.cancellable?

        redirect_to [:dashboard, @discovery_session], alert: t('.already_confirmed')
      end
    end
  end
end
