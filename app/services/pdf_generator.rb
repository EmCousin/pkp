# frozen_string_literal: true

class PdfGenerator
  def self.setup_document
    Prawn::Document.new(margin: [20, 30]) do |pdf|
      begin
        # Try to get logo from assets
        logo_path = if Rails.env.test?
                      Rails.root.join('app/assets/images/parkourparis.jpg')
                    else
                      Propshaft.resolve('parkourparis.jpg')
                    end

        pdf.image logo_path, width: 150 if logo_path && File.exist?(logo_path)
      rescue Propshaft::MissingAssetError => e
        Rails.logger.warn "Logo not found: #{e.message}"
        # Continue without the logo
      end

      yield pdf if block_given?
    end
  end
end
