# frozen_string_literal: true

module Dashboard
  class SubscriptionsController < DashboardController
    include AccessFilters

    before_action :filter_available_members!, only: %i[new], unless: :available_members?
    before_action :set_member, only: %i[new]
    before_action :set_subscription, only: %i[show]

    def show; end

    def new
      @subscription = current_user.subscriptions.new(member: @member)
    end

    def create
      @subscription = current_user.subscriptions.new(subscription_params)
      if @subscription.save
        redirect_to next_completion_step_path(@subscription), status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    def set_subscription
      @subscription = current_user.subscriptions.find_by(id: params[:id])
    end

    def subscription_params
      params.expect(
        subscription: [:member_id,
                       :category_id,
                       { course_ids: [] }]
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
