# frozen_string_literal: true

module Admin
  class InvoicesController < AdminController
    before_action :set_subscription!, only: %i[show edit update]

    def show
      def pdf_convertion
        respond_to do |format|
          format.html
          format.pdf do
            render pdf: "facture"
          end
        end
      end
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
        year: Time.now.year
      )
    end

    def subscription_params
      params.require(:subscription).permit(
        :invoice
      )
    end
  end
end
