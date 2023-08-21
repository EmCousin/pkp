# frozen_string_literal: true

module Admin
  class InvoicesController < Admin::Abstract::SubscriptionsController
    before_action :set_subscription!, only: %i[show create edit update]

    def show; end

    def edit; end

    def create
      @subscription.invoice.attach(
        io: StringIO.new(pdf(@subscription)),
        filename: 'invoice.pdf',
        content_type: Mime[:pdf]
      )

      redirect_to admin_subscription_path(@subscription.id), notice: t('.success'), status: :see_other
    end

    def update
      if @subscription.update(subscription_params)
        redirect_to admin_subscription_path(@subscription.id), notice: t('.success')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def subscription_params
      params.require(:subscription).permit(:invoice)
    end

    def pdf(subscription)
      WickedPdf.new.pdf_from_string(
        render_to_string(
          'templates/invoice.html.erb',
          layout: 'invoice.html.erb',
          encoding: 'UTF-8',
          locals: {
            subscription:
          }
        )
      ).force_encoding('UTF-8')
    end
  end
end
