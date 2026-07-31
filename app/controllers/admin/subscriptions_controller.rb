# frozen_string_literal: true

module Admin
  class SubscriptionsController < BaseController
    before_action :set_subscription!, only: %i[show edit update destroy unlink_course]
    before_action :reject_event_edit!, only: %i[edit update], if: -> { @subscription.event? }

    def index
      @subscriptions = Subscription.search_and_filter(params.to_unsafe_h.slice(:status, :level, :year, :course_ids, :camp_id))
                                   .order(created_at: :desc)
                                   .page(params[:page])
                                   .per(params[:per_page] || 25)
                                   .includes(:camp, :courses, member: :avatar_attachment)
                                   .with_attached_medical_certificate
    end

    def show; end

    def new
      @subscription = AnnualSubscription.new(
        member_id: params[:member_id],
        course_ids: params[:course_ids]
      )
    end

    def edit; end

    def create
      @subscription = subscription_class.new(subscription_params)
      if save_subscription
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
      if @subscription.destroy
        redirect_to admin_subscriptions_path(destroyed: true), notice: t('.success'), status: :see_other
      else
        redirect_to admin_subscriptions_path, alert: t('.error'), status: :see_other
      end
    end

    def unlink_course
      @course = @subscription.courses.find(params[:course_id])
      @subscription.courses_subscriptions.destroy_by(course_id: @course.id)
      redirect_back_or_to(:root, notice: t('.success'))
    end

    private

    def set_subscription!
      @subscription = Subscription.find(params[:id])
    end

    def subscription_params
      attributes = params.expect(
        subscription: [:member_id, :status, :parent_subscription_id, { course_ids: [] }, { camps_subscription_attributes: [:camp_id] }]
      )
      attributes.delete(:camps_subscription_attributes) if @subscription&.persisted?
      attributes
    end

    def save_subscription
      camp = @subscription.subscription_camp
      camp ? camp.with_lock { @subscription.save } : @subscription.save
    end

    def subscription_class
      subscription_params.dig(:camps_subscription_attributes, :camp_id).present? ? CampRegistration : AnnualSubscription
    end

    def reject_event_edit!
      redirect_to [:admin, @subscription], alert: t('.event_not_editable'), status: :see_other
    end
  end
end
