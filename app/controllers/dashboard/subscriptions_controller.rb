# frozen_string_literal: true

module Dashboard
  class SubscriptionsController < DashboardController

    def new
      @subscription = Subscription.new

      category = params[:category]
      if category.present?
        @courses = Course.where(category: category)
      end
    end

    def create
      @subscription = current_user.subscriptions.new(subscription_params)
      @subscription.year = Time.now.year
      @subscription.fee = 0
      if @subscription.save
        @subscription.fee = @subscription.compute_fee
        @subscription.save
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
