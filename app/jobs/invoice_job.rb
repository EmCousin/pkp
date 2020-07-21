# frozen_string_literal: true

class InvoiceJob < ApplicationJob
  def perform(subscription)
    subscription.invoice.attach(
      io: StringIO.new(pdf(subscription)),
      filename: 'invoice.pdf',
      content_type: Mime[:pdf]
    )
  end

  private

  def pdf(subscription)
    WickedPdf.new.pdf_from_string(
      ApplicationController.new.render_to_string(
        'templates/invoice.html.erb',
        layout: 'invoice.html.erb',
        encoding: 'UTF-8',
        locals: {
          subscription: subscription
        }
      )
    ).force_encoding('UTF-8')
  end
end
