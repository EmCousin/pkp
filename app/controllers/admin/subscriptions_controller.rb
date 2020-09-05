# frozen_string_literal: true

module Admin
  class SubscriptionsController < AdminController
    include Subscriptions::Pdf
    before_action :set_subscription!, only: %i[show edit update destroy confirm archive unlink_course]

    def index
      @subscriptions = Subscription.filter_by_status(params[:status])
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
        redirect_to admin_subscriptions_path, notice: t('.success')
      else
        render :new
      end
    end

    def edit; end

    def update
      if @subscription.update(subscription_params)
        process_after_save(@subscription)
        redirect_to admin_subscription_path(@subscription.id), notice: t('.success')
      else
        render :edit
      end
    end

    def destroy
      @subscription.destroy
      redirect_to admin_subscriptions_path, notice: t('.success')
    end

    def unlink_course
      @course = @subscription.courses.find(params[:course_id])
      @subscription.courses_subscriptions.destroy_by(course_id: @course.id)
      redirect_back fallback_location: root_path, notice: t('.success')
    end

    def confirm
      if @subscription.confirmed?
        redirect_back fallback_location: admin_subscriptions_path, alert: t('.failure')
      else
        @subscription.confirmed!
        redirect_back fallback_location: admin_subscriptions_path, notice: t('.success')
      end
    end

    def archive
      if @subscription.archived?
        redirect_back fallback_location: admin_subscriptions_path, alert: t('.failure')
      else
        @subscription.archived!
        redirect_back fallback_location: admin_subscriptions_path, notice: t('.success')
      end
    end

    private

    def set_subscription!
      @subscription = Subscription.find(params[:id])
    end

    def subscription_params
      params.require(:subscription).permit(:member_id, course_ids: [])
    end
  end
end
