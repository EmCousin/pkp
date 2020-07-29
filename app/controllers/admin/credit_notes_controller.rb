# frozen_string_literal: true

module Admin
  class CreditNotesController < AdminController
    before_action :set_subscription!, only: %i[new create]

    def new; end

    def create
      @subscription.assign_attributes(subscription_params)
      pdf = pdf_credit_note

      @subscription.credit_notes.attach(
        io: StringIO.new(pdf),
        filename: 'credit_note.pdf',
        content_type: Mime[:pdf]
      )

      redirect_to admin_subscription_path(@subscription.id), notice: t('.success')
    end

    private

    def set_subscription!
      @subscription = Subscription.find_by!(
        id: params[:subscription_id],
        year: Subscription.current_year
      )
    end

    def pdf_credit_note
      WickedPdf.new.pdf_from_string(
        render_to_string(
          'templates/credit_note.html.erb',
          layout: 'pdf.html.erb',
          encoding: 'UTF-8',
          locals: {
            subscription: @subscription
          }
        )
      ).force_encoding('UTF-8')
    end

    def subscription_params
      params.require(:subscription).permit(
        :credit_note_amount
      )
    end
  end
end
