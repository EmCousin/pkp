# frozen_string_literal: true

module Dashboard
  class SubscriptionsController < DashboardController
    def new
      @form = CreateSubscriptionForm.new(subscription_params)
    end

    def create
      @form = CreateSubscriptionForm.new(subscription_params)
      if @form.submit
        SubscriptionMailer.confirm_subscription(@form.subscription).deliver_now
        redirect_to dashboard_index_path, notice: 'Inscription créée avec succès !'
      else
        render :new
      end
    end

    private

    def subscription_params
      if params[:create_subscription_form].present?
        params.require(:create_subscription_form).permit(:category, course_ids: []).merge(user: current_user)
      else
        {}
      end
    end
  end
end
