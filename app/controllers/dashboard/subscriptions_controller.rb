# frozen_string_literal: true

module Dashboard
  class SubscriptionsController < DashboardController
    before_action :filter_vacation_time!, only: %i[new create], if: :vacation_time?
    before_action :filter_full!, only: %i[new create], if: :full?

    VACATION_MONTHS = (7..8).freeze

    def new
      @form = CreateSubscriptionForm.new(subscription_params)
    end

    def create
      @form = CreateSubscriptionForm.new(subscription_params)
      if @form.submit
        SubscriptionMailer.confirm_subscription(@form.subscription).deliver_later
        redirect_to dashboard_index_path, notice: 'Inscription créée avec succès !'
      else
        render :new
      end
    end

    private

    def subscription_params
      if params[:create_subscription_form].present?
        params.require(:create_subscription_form).permit(:category, course_ids: []).merge(user: current_user)
      else
        {}
      end
    end

    def filter_vacation_time!
      redirect_to dashboard_vacations_path
    end

    def vacation_time?
      Time.now.month.in?(VACATION_MONTHS)
    end

    def filter_full!
      return redirect_to dashboard_capacities_path
    end

    def full?
      Course.all.all? do |course|
        active_subscriptions = course.subscriptions.where(year: Time.now.year).where.not(status: 'archived')
        course.capacity <= active_subscriptions.count
      end
    end
  end
end
