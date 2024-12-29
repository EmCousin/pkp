# frozen_string_literal: true

class PdfGenerator
  def self.setup_document
    Prawn::Document.new(margin: [20, 30]) do |pdf|
      add_logo(pdf)
      yield pdf if block_given?
    end
  end

  def self.add_logo(pdf)
    logo_path = Rails.env.test? ? Rails.root.join('app/assets/images/parkourparis.jpg') : Propshaft.resolve('parkourparis.jpg')
    pdf.image logo_path, width: 150 if logo_path && File.exist?(logo_path)
  rescue Propshaft::MissingAssetError => e
    Rails.logger.warn "Logo not found: #{e.message}"
  end
  private_class_method :add_logo
end
