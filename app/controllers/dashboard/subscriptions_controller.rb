# frozen_string_literal: true

module Dashboard
  class SubscriptionsController < DashboardController
    before_action :filter_vacation_time!, only: %i[new create], unless: :vacation_time?
    before_action :filter_full!, only: %i[new create], if: :full?
    before_action :filter_available_members!, only: %i[new], unless: :available_members?
    before_action :set_member, only: %i[new]

    def new
      @subscription = current_user.subscriptions.new(member: @member)
    end

    def create
      @subscription = current_user.subscriptions.new(subscription_params)

      if @subscription.save
        process_after_save
        redirect_to dashboard_index_path, notice: 'Inscription créée avec succès !'
      else
        render :new
      end
    end

    private

    def subscription_params
      params.require(:subscription).permit(
        :category,
        :member_id,
        course_ids: []
      )
    end

    def filter_vacation_time!
      redirect_to dashboard_vacations_path
    end

    def vacation_time?
      Time.current.month.in?(Course::VACATION_MONTHS)
    end

    def filter_full!
      redirect_to dashboard_capacities_path
    end

    def full?
      Course.available.empty?
    end

    def filter_available_members!
      redirect_to new_dashboard_member_path, notice: t('.create_member')
    end

    def available_members?
      current_user.members.available.any?
    end

    def set_member
      @member = Member.find_by(id: params[:member_id])
    end

    def process_after_save
      @subscription.form.attach(
        io: StringIO.new(pdf_from_subscription(@subscription)),
        filename: 'fiche.pdf',
        content_type: Mime[:pdf]
      )

      SubscriptionMailer.confirm_subscription(@subscription).deliver_later
    end

    def pdf_from_subscription(subscription)
      WickedPdf.new.pdf_from_string(
        render_to_string(
          'templates/subscription.html.erb',
          layout: 'pdf.html.erb',
          encoding: 'UTF-8',
          locals: { subscription: subscription, logo_url: nil }
        )
      ).force_encoding('UTF-8')
    end
  end
end
