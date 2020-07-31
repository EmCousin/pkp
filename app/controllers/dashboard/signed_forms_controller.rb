# frozen_string_literal: true

module Dashboard
  class SignedFormsController < DashboardController
    before_action :filter_enabled!
    before_action :set_subscription, only: %i[edit update]

    def edit; end

    def update
      if @subscription.update(subscription_params)
        redirect_to dashboard_index_path, notice: t('.edit_success')
      else
        render :edit
      end
    end

    private

    def filter_enabled!
      return false if Rails.application.credentials.signed_form[:enabled]

      redirect_to dashboard_index_path, alert: t('defaults.forbidden')
    end

    def set_subscription
      @subscription = current_user.subscriptions.find_by!(
        id: params[:subscription_id],
        year: Subscription.current_year
      )
    end

    def subscription_params
      params.require(:subscription).permit(
        :signed_form
      )
    end
  end
end
