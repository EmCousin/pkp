# frozen_string_literal: true

module Admin
  class CreditNotesController < AdminController
    before_action :set_subscription!, only: %i[new create]

    def new; end

    def create
      redirect_to admin_subscription_path(@subscription.id), notice: t('.success')
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
        :credit_note_amount
      )
    end
  end
end
