# frozen_string_literal: true

module Dashboard
  class TermsController < Dashboard::Abstract::SubscriptionsController
    before_action :set_subscription!, only: %i[edit update]
    before_action :filter_already_accepted!, only: %i[edit update]

    def edit; end

    def update
      if @subscription.update(subscription_params)
        @subscription.confirm! if @subscription.completed?
        redirect_to next_completion_step_path(@subscription), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def subscription_params
      params.expect(subscription: [:terms_accepted])
    end

    def filter_already_accepted!
      redirect_to :dashboard, alert: t('.already_accepted') if @subscription.terms_accepted_at?
    end
  end
end
