# frozen_string_literal: true

module Dashboard
  class SubscriptionsController < DashboardController
    include AccessFilters
    include Subscriptions::Pdf

    before_action :filter_available_members!, only: %i[new], unless: :available_members?
    before_action :set_member, only: %i[new]

    def new
      @subscription = current_user.subscriptions.new(member: @member)
    end

    def create
      @subscription = current_user.subscriptions.new(subscription_params)

      if @subscription.save
        process_after_save(@subscription)
        redirect_to dashboard_index_path, notice: t('.success'), status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def subscription_params
      params.require(:subscription).permit(
        :member_id,
        :category_id,
        course_ids: []
      )
    end

    def filter_available_members!
      redirect_to new_dashboard_member_path, notice: t('.create_member')
    end

    def available_members?
      current_user.members.available.any?
    end

    def set_member
      @member = current_user.members.find_by(id: params[:member_id])
    end
  end
end
