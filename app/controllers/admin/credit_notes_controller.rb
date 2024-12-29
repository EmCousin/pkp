# frozen_string_literal: true

module Admin
  class CreditNotesController < Admin::Abstract::SubscriptionsController
    before_action :set_subscription!, only: %i[new create]

    def new; end

    def create
      @subscription.assign_attributes(subscription_params)

      @subscription.credit_notes.attach(
        io: StringIO.new(generate_credit_note_pdf.render),
        filename: 'credit_note.pdf',
        content_type: 'application/pdf'
      )

      redirect_to admin_subscription_path(@subscription.id), notice: t('.success'), status: :see_other
    end

    private

    def generate_credit_note_pdf
      PdfGenerator.setup_document { |pdf| add_credit_note_content(pdf) }
    end

    def add_credit_note_content(pdf)
      add_header(pdf)
      add_company_info(pdf)
      add_client_info(pdf)
      add_credit_note_details(pdf)
      add_footer(pdf)
    end

    def add_header(pdf)
      pdf.move_down 20
      pdf.text 'AVOIR', size: 22, style: :bold
      pdf.move_down 20
    end

    def add_company_info(pdf)
      pdf.text 'Parkour Paris', size: 14, style: :bold
      pdf.text '123 Rue de Paris'
      pdf.text '75000 Paris'
      pdf.text 'SIRET: XXXXXXXXXXXXXXXXX'
      pdf.move_down 20
    end

    def add_client_info(pdf)
      pdf.text 'Client:', size: 14, style: :bold
      pdf.text @subscription.full_name
      pdf.text @subscription.address if @subscription.address.present?
      pdf.text @subscription.email
      pdf.move_down 20
    end

    def add_credit_note_details(pdf)
      format_credit_note_table(pdf)
      pdf.move_down 20
      pdf.text "Total: #{@subscription.credit_note_amount}€", align: :right, size: 16, style: :bold
    end

    def format_credit_note_table(pdf)
      items = [
        %w[Description Montant],
        ["Avoir sur #{@subscription.course_name}", "#{@subscription.credit_note_amount}€"]
      ]

      pdf.table(items, width: pdf.bounds.width) do
        cells.padding = [12, 6]
        cells.borders = [:bottom]
        row(0).font_style = :bold
        column(1).align = :right
      end
    end

    def add_footer(pdf)
      pdf.move_down 40
      pdf.text "Date: #{I18n.l(Date.current, format: :long)}", align: :right
      pdf.text "Numéro d'avoir: CN-#{@subscription.id}-#{Time.current.to_i}", align: :right
    end

    def subscription_params
      params.require(:subscription).permit(:credit_note_amount)
    end
  end
end
