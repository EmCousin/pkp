# frozen_string_literal: true

module Admin
  class SubscriptionsController < BaseController
    before_action :set_subscription!, only: %i[show edit update destroy unlink_course]
    before_action :reject_event_edit!, only: %i[edit update], if: -> { @subscription.event? }
    before_action :reject_invoiced_edit!, only: %i[edit update unlink_course], if: -> { @subscription.billing_invoice }

    def index
      @subscriptions = Subscription.search_and_filter(
        params.to_unsafe_h.slice(:status, :level, :year, :course_ids, :camp_id, :discovery_session_id)
      )
                                   .order(created_at: :desc)
                                   .page(params[:page])
                                   .per(params[:per_page] || 25)
                                   .includes(:camp, :courses, { discovery_session: :course }, member: :avatar_attachment)
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
      if @subscription.with_lock { @subscription.update(subscription_params) }
        redirect_to admin_subscription_path(@subscription, updated: true), notice: t('.success'), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @subscription.destroy
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to admin_subscriptions_path, notice: t('.success'), status: :see_other }
        end
      else
        redirect_to admin_subscriptions_path, alert: t('.error'), status: :see_other
      end
    end

    def unlink_course
      @course = @subscription.courses.find(params[:course_id])
      @subscription.with_lock do
        @subscription.courses_subscriptions.destroy_by(course_id: @course.id) unless @subscription.billing_invoice
      end
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

    def reject_invoiced_edit!
      redirect_to [:admin, @subscription], alert: t('.invoiced_not_editable'), status: :see_other
    end
  end
end
