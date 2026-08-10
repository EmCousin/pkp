# frozen_string_literal: true

module Admin
  class InvoicesController < Admin::Abstract::SubscriptionsController
    before_action :set_subscription!, only: %i[show create edit update]

    def show; end

    def edit; end

    def create
      invoice = @subscription.billing_invoice
      queued = invoice ? invoice.retry! : @subscription.request_billing_invoice!.present?

      redirect_to admin_subscription_path(@subscription.id),
                  **(queued ? { notice: t('.queued') } : { alert: t('.not_queued') }),
                  status: :see_other
    end

    def update
      if @subscription.update(subscription_params)
        redirect_to admin_subscription_path(@subscription.id), notice: t('.success')
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def subscription_params
      params.expect(subscription: [:invoice])
    end
  end
end
