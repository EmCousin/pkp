# frozen_string_literal: true

module Dashboard
  class TermsController < Dashboard::Abstract::SubscriptionsController
    before_action :set_subscription!, only: %i[edit update]
    before_action :filter_already_accepted!, only: %i[edit update]

    def edit; end

    def update
      if @subscription.update(subscription_params)
        redirect_to :dashboard, notice: t('.success')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def subscription_params
      params.require(:subscription).permit(:terms_accepted)
    end

    def filter_already_accepted!
      redirect_to :dashboard, alert: t('.already_accepted') if @subscription.terms_accepted_at?
    end
  end
end
