# frozen_string_literal: true

class PdfGenerator
  def self.setup_document
    Prawn::Document.new(margin: [20, 30]) do |pdf|
      # Add logo image
      logo_path = Rails.root.join('app/assets/images/parkourparis.jpg')
      pdf.image logo_path, width: 150 if File.exist?(logo_path)

      yield pdf if block_given?
    end
  end
end
