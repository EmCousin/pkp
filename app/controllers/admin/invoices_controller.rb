# frozen_string_literal: true

module Admin
  class InvoicesController < AdminController
    before_action :set_subscription!, only: %i[show create edit update]

    def show; end

    def create
      InvoiceJob.perform_now(@subscription)

      redirect_to admin_subscription_path(@subscription.id), notice: t('.success')
    end

    def edit; end

    def update
      if @subscription.update(subscription_params)
        redirect_to admin_subscription_path(@subscription.id), notice: t('.edit_success')
      else
        render :edit
      end
    end

    private

    def set_subscription!
      @subscription = Subscription.find_by!(
        id: params[:subscription_id],
        year: Subscription.current_year
      )
    end

    def subscription_params
      params.require(:subscription).permit(
        :invoice
      )
    end
  end
end
