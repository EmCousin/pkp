# frozen_string_literal: true

module Admin
  class InvoicesController < AdminController
    before_action :set_subscription!, only: %i[create]

    def create
      invoice = @subscription.create_invoice

      if invoice.valid?
        redirect_back fallback_location: admin_subscription_path(@subscription.id), notice: t('.invoice_success')
      else
        redirect_back fallback_location: admin_subscription_path(@subscription.id), alert: invoice.errors.full_messages.join(', ')
      end
    end

    private

    def set_subscription!
      @subscription = Subscription.find_by!(
        id: params[:subscription_id],
        year: Time.now.year
      )
    end
  end
end
