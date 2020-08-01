# frozen_string_literal: true

module Admin
  class SubscriptionsController < AdminController
    include Subscriptions::Pdf
    before_action :set_subscription!, only: %i[show edit update destroy confirm archive unlink_course]

    def index
      @subscriptions = Subscription.includes(:member).order(created_at: :desc).page(params[:page]).per(50)
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
        redirect_to admin_subscriptions_path, notice: 'Inscription créée avec succès !'
      else
        render :new
      end
    end

    def edit; end

    def update
      if @subscription.update(subscription_params)
        process_after_save(@subscription)
        redirect_to admin_subscription_path(@subscription.id), notice: 'Inscription modifiée avec succès !'
      else
        render :edit
      end
    end

    def destroy
      @subscription.destroy
      redirect_to admin_subscriptions_path, notice: 'Inscription supprimée avec succès !'
    end

    def unlink_course
      @course = @subscription.courses.find(params[:course_id])
      @subscription.courses.destroy_by(id: @course.id)
      redirect_back fallback_location: root_path, notice: 'Cours retiré avec succès !'
    end

    def confirm
      if subscription.confirmed?
        redirect_back fallback_location: admin_subscriptions_path, alert: t('.confirmation_failure')
      else
        subscription.confirmed!
        redirect_back fallback_location: admin_subscriptions_path, notice: t('.confirmation_success')
      end
    end

    def archive
      if subscription.archived?
        redirect_back fallback_location: admin_subscriptions_path, alert: t('.archivation_failure')
      else
        subscription.archived!
        redirect_back fallback_location: admin_subscriptions_path, notice: t('.archivation_success')
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
