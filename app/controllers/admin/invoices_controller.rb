# frozen_string_literal: true

module Admin
  class InvoicesController < Admin::Abstract::SubscriptionsController
    before_action :set_subscription!, only: %i[show create edit update]

    def show; end

    def edit; end

    def create
      @subscription.invoice.attach(
        io: StringIO.new(generate_invoice_pdf.render),
        filename: 'invoice.pdf',
        content_type: 'application/pdf'
      )

      redirect_to admin_subscription_path(@subscription.id), notice: t('.success'), status: :see_other
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

    def generate_invoice_pdf
      PdfGenerator.setup_document do |pdf|
        # Header with logo and company info
        add_header_section(pdf)
        add_invoice_details(pdf)
        add_items_table(pdf)
        add_totals_section(pdf)
      end
    end

    # rubocop:disable Metrics/AbcSize
    def add_header_section(pdf)
      # Company info (left side)
      pdf.text Rails.configuration.company[:name], size: 16, style: :bold
      pdf.text "SIRET : #{Rails.configuration.company[:siret]}"
      pdf.text Rails.configuration.company[:address]
      pdf.text Rails.configuration.company[:email]
      pdf.text "N° TVA intracommunautaire : #{Rails.configuration.company[:vat_number]}"
      pdf.move_down 20

      # Client info
      pdf.text @subscription.member.full_name
      pdf.text @subscription.member.address
      pdf.text "#{@subscription.member.zip_code} #{@subscription.member.city}"
      pdf.text @subscription.member.country
      pdf.text @subscription.member.email
      pdf.text @subscription.member.phone_number
    end
    # rubocop:enable Metrics/AbcSize

    def add_invoice_details(pdf)
      pdf.move_down 20
      pdf.text "Facture: ##{@subscription.year}#{@subscription.id}", size: 14, style: :bold
      pdf.text "Payée le: #{l(@subscription.paid_at, format: :short)}"
      pdf.text "Date de délivrance : #{l(Time.current, format: :short)}"
      pdf.move_down 20
    end

    def add_items_table(pdf)
      pdf.table(invoice_items_data, width: pdf.bounds.width) do |table|
        apply_items_table_styles(table)
      end
    end

    def invoice_items_data
      [
        %w[Cours Prix Quantité Total],
        [
          @subscription.description,
          helpers.number_to_euros(@subscription.fee),
          '1',
          helpers.number_to_euros(@subscription.fee)
        ]
      ]
    end

    def apply_items_table_styles(table)
      table.cells.padding = [12, 6]
      table.cells.borders = [:bottom]
      table.row(0).font_style = :bold
      table.column(1..3).align = :right
    end

    def add_totals_section(pdf)
      pdf.move_down 20
      pdf.table(totals_data, width: pdf.bounds.width, cell_style: { borders: [] }) do |table|
        apply_totals_table_styles(table)
      end
    end

    def totals_data
      [
        ['Sous-total :', helpers.number_to_euros(@subscription.fee)],
        ['Total facture :', helpers.number_to_euros(@subscription.fee)],
        ['Montant payé :', helpers.number_to_euros(@subscription.paid_amount)],
        ['Solde :', helpers.number_to_euros(@subscription.balance)]
      ]
    end

    def apply_totals_table_styles(table)
      table.cells.padding = [5, 6]
      table.column(0).align = :right
      table.column(1).align = :right
      table.rows(2..3).font_style = :bold
    end
  end
end
