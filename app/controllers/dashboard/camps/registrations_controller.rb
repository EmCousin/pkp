# frozen_string_literal: true

module Dashboard
  module Camps
    class RegistrationsController < DashboardController
      before_action :set_available_camp, only: :create
      before_action :set_member, only: :create
      before_action :set_registration, only: :destroy
      before_action :check_cancellable, only: :destroy
      before_action :check_open_status, only: :create

      def create
        raise ActiveRecord::RecordNotFound if @member.annual_subscription_for(@camp.year)

        @registration = CampRegistration.new(member: @member, year: @camp.year,
                                             camps_subscription_attributes: { camp_id: @camp.id })

        if @camp.with_lock { @registration.save }
          redirect_to next_completion_step_path(@registration), status: :see_other
        else
          redirect_back_or_to [:dashboard, @camp], alert: @registration.errors.full_messages.to_sentence
        end
      end

      def destroy
        if @registration.destroy
          redirect_back_or_to [:dashboard, @camp], notice: t('.success'), status: :see_other
        else
          redirect_back_or_to [:dashboard, @camp], alert: t('.error'), status: :unprocessable_content
        end
      end

      private

      def set_member
        @member = current_user.members.find_by!(platform: Current.platform, id: params.require(:member_id))
      end

      def set_available_camp
        @camp = Current.platform.camps.available.find(params.expect(:camp_id))
      end

      def set_registration
        @registration = current_user.subscriptions
                                    .for_platform(Current.platform)
                                    .where(type: CampRegistration.sti_name, parent_subscription_id: nil)
                                    .joins(:camp)
                                    .find_by!(id: params.expect(:id), camps: { id: params.expect(:camp_id) })
        @camp = @registration.camp
      end

      def check_open_status
        redirect_to [:dashboard, @camp], alert: t('.closed') unless @camp.open_to_externals?
      end

      def check_cancellable
        redirect_to [:dashboard, @camp], alert: t('.already_confirmed') unless @registration.cancellable?
      end
    end
  end
end
