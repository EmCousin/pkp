# frozen_string_literal: true

module Admin
  class InvoicesController < AdminController
    before_action :set_subscription!, only: %i[show create edit update]

    def show; end

    def create
      pdf = pdf_from_subscription
      @subscription.invoice.attach(pdf)
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
        year: Time.now.year
      )
    end

    def pdf_from_subscription
      WickedPdf.new.pdf_from_string(
        render_to_string(
          'templates/invoice.html.erb',
          layout: 'pdf.html.erb',
          encoding: 'UTF-8',
          locals: {
            subscription: @subscription
          }
        )
      )
    end

    def subscription_params
      params.require(:subscription).permit(
        :invoice
      )
    end
  end
end
