# frozen_string_literal: true

module Dashboard
  class SubscriptionsController < DashboardController
    def new
      @subscription = Subscription.new

      category = params[:category]
      @courses = Course.where(category: category) if category.present?
    end

    def create
      subscription = current_user.subscriptions.new(subscription_params)
      @subscription = CreateSubscriptionService.new(subscription).perform!
      if @subscription.valid?
        redirect_to dashboard_index_path, notice: 'Inscription créée avec succès !'
      else
        render :new
      end
    end

    private

    def subscription_params
      params.require(:subscription).permit(course_ids: [])
    end
  end
end
