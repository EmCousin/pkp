# frozen_string_literal: true

module Admin
  class SubscriptionsController < BaseController
    before_action :set_subscription!, only: %i[show edit update destroy unlink_course]

    def index
      @subscriptions = Subscription.search_and_filter(params.to_unsafe_h.slice(:status, :level, :year, :course_ids, :camp_id))
                                   .order(created_at: :desc)
                                   .page(params[:page])
                                   .per(25)
                                   .includes(:camp, :courses, member: :avatar_attachment)
    end

    def show; end

    def new
      @subscription = Subscription.new(
        member_id: params[:member_id],
        course_ids: params[:course_ids]
      )
    end

    def edit; end

    def create
      @subscription = Subscription.new(subscription_params)
      if @subscription.save
        redirect_to %i[admin subscriptions], notice: t('.success'), status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @subscription.update(subscription_params)
        redirect_to admin_subscription_path(@subscription, updated: true), notice: t('.success'), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @subscription.destroy
      redirect_to admin_subscriptions_path(destroyed: true), notice: t('.success'), status: :see_other
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
      params.expect(subscription: [:member_id, :status, :parent_subscription_id, { course_ids: [] }, { camps_subscription_attributes: [:camp_id] }])
    end
  end
end
