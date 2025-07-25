# frozen_string_literal: true

module Subscriptions
  module Pdf # rubocop:disable Metrics/ModuleLength
    extend ActiveSupport::Concern

    include ActionView::Helpers::NumberHelper

    private

    def process_after_save(subscription)
      subscription.reload
      pdf = generate_subscription_pdf(subscription)
      attach_pdf_to_subscription(subscription, pdf)
      SubscriptionMailer.confirm_subscription(subscription).deliver_later
    end

    def attach_pdf_to_subscription(subscription, pdf)
      subscription.form.attach(
        io: StringIO.new(pdf.render),
        filename: 'fiche.pdf',
        content_type: Mime[:pdf]
      )
    end

    def generate_subscription_pdf(subscription)
      PdfGenerator.setup_document do |pdf|
        add_header_section(pdf, subscription)
        add_member_info_table(pdf, subscription)
        add_terms_and_signature(pdf, subscription)
      end
    end

    def add_header_section(pdf, subscription)
      pdf.move_down 10
      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: 100) do
        add_avatar(pdf, subscription)
        add_title_and_name(pdf, subscription)
      end
      pdf.move_down 20
    end

    def add_avatar(pdf, subscription)
      return unless subscription.member.avatar.attached?

      pdf.float do
        pdf.image StringIO.new(subscription.member.avatar.download),
                  width: 60,
                  position: :left
      end
    end

    def add_title_and_name(pdf, subscription)
      pdf.float do
        pdf.bounding_box([100, pdf.cursor], width: pdf.bounds.width - 100, height: 100) do
          pdf.text "Inscription #{subscription.year} / #{subscription.year + 1}",
                   size: 18, style: :bold, align: :right
          pdf.text "#{subscription.member.last_name.upcase} #{subscription.member.first_name}",
                   size: 16, style: :bold, align: :right
        end
      end
    end

    def add_member_info_table(pdf, subscription)
      pdf.move_down 10
      pdf.table(member_info_data(subscription), width: pdf.bounds.width) do |table|
        apply_table_styles(table)
      end
    end

    def apply_table_styles(table)
      table.cells.padding = [5, 6]
      table.cells.borders = [:bottom]
      table.cells.border_width = 0.5
      table.cells.size = 10
      table.column(0).font_style = :bold
      table.column(0).width = 130
    end

    def member_info_data(subscription)
      basic_info(subscription) + contact_info(subscription)
    end

    def basic_info(subscription)
      [
        ['Type de cours choisi', subscription.description],
        ['Date de naissance', I18n.l(subscription.member.birthdate, format: :long)],
        ['Adresse', subscription.member.address],
        ['Code postal', subscription.member.zip_code],
        ['Ville', subscription.member.city],
        ['Pays', subscription.member.country]
      ]
    end

    def contact_info(subscription)
      [
        ['Téléphone', subscription.member.phone_number],
        ['E-mail', subscription.member.email],
        ['Contact', subscription.member.contact_name],
        ['Lien de parenté', subscription.member.contact_relationship],
        ['Téléphone du contact', subscription.member.contact_phone_number],
        ["Droit à l'image", subscription.member.agreed_to_advertising_right ? 'Oui' : 'Non'],
        ['Tarif', format_currency(subscription.fee)]
      ]
    end

    def format_currency(amount)
      number_to_currency(amount, unit: '€', separator: ',', format: '%n %u')
    end

    def add_terms_and_signature(pdf, subscription)
      pdf.move_down 10
      pdf.font_size 9 do
        add_terms(pdf)
        add_medical_notice(pdf, subscription)
      end
      add_acceptance_section(pdf, subscription)
    end

    def add_terms(pdf)
      pdf.move_down 20
      pdf.text terms_text, size: 11
    end

    def terms_text
      'Je certifie avoir pris connaissance des activités proposées ' \
        "par l'Association ParKour Paris et déclare qu'elles n'engagent " \
        "que ma seule responsabilité en cas d'accident ou d'incident"
    end

    def add_medical_notice(pdf, subscription)
      return unless subscription.doctor_certified_at?

      pdf.move_down 15
      pdf.text medical_notice_text(subscription), size: 11
    end

    def medical_notice_text(subscription)
      "#{subscription.member.full_name} a certifié avoir un " \
        'certificat médical pour cette inscription.'
    end

    def add_acceptance_section(pdf, subscription)
      pdf.move_down 15
      add_acceptance_notice(pdf)
      add_acceptance_box(pdf, subscription)
    end

    def add_acceptance_notice(pdf)
      pdf.text 'Merci de bien vouloir apporter cette fiche lors de votre premier cours.',
               size: 11, style: :bold
    end

    def add_acceptance_box(pdf, subscription)
      pdf.move_down 10
      pdf.stroke_rectangle [0, pdf.cursor], 300, 60
      pdf.move_down 5
      pdf.text(
        "#{subscription.member.full_name} a accepté les conditions générales d'utilisation " \
        'et particulières relatives aux cours décrits dans cette fiche.',
        size: 10
      )
    end
  end
end
