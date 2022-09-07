# frozen_string_literal: true

module Admin
  class SubscriptionsController < AdminController
    include Subscriptions::Pdf
    before_action :set_subscription!, only: %i[show edit update destroy confirm archive unlink_course]

    def index
      @subscriptions = Subscription.filter_by_status(params[:status])
                                   .where(year: params[:year] || Subscription.current_year)
                                   .order(created_at: :desc)
                                   .page(params[:page])
                                   .per(25)
                                   .includes(:courses, member: :avatar_attachment)
    end

    def show; end

    def new
      @subscription = Subscription.new(
        member_id: params[:member_id],
        course_ids: params[:course_ids]
      )
    end

    def create
      @subscription = Subscription.new(subscription_params)
      if @subscription.save
        process_after_save(@subscription)
        redirect_to %i[admin subscriptions], notice: t('.success'), status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @subscription.update(subscription_params)
        process_after_save(@subscription) unless params[:no_notification]
        redirect_back_or_to [:admin, @subscription], notice: t('.success'), status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @subscription.destroy
      redirect_to %i[admin subscriptions], notice: t('.success'), status: :see_other
    end

    def unlink_course
      @course = @subscription.courses.find(params[:course_id])
      @subscription.courses_subscriptions.destroy_by(course_id: @course.id)
      redirect_back fallback_location: :root, notice: t('.success')
    end

    private

    def set_subscription!
      @subscription = Subscription.find(params[:id])
    end

    def subscription_params
      params.require(:subscription).permit(:member_id, :status, course_ids: [])
    end
  end
end
