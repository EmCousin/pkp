# frozen_string_literal: true

module Dashboard
  class SubscriptionFormsController < DashboardController
    before_action :set_subscription, only: %i[create]

    def create
      file = Tempfile.open(['fiche', '.pdf']) do |f|
        f << pdf_from_subscription(@subscription)
      end

      respond_to do |format|
        format.html do
          send_file file.path, type: Mime[:pdf],
                               disposition: 'attachment'
        end
      end
    end

    private

    def set_subscription
      @subscription = current_user.subscriptions.find_by!(
        id: params[:subscription_id],
        year: Subscription.current_year
      )
    end

    def pdf_from_subscription(subscription)
      WickedPdf.new.pdf_from_string(
        render_to_string(
          'templates/subscription.html.erb',
          layout: 'pdf.html.erb',
          encoding: 'UTF-8',
          locals: {
            subscription: subscription
          }
        )
      ).force_encoding('UTF-8')
    end
  end
end
