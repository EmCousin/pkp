# frozen_string_literal: true

module Admin
  class SubscriptionsController < AdminController
    def index
      @subscriptions = Subscription.includes(:member).order(created_at: :desc).page(params[:page]).per(50)
    end

    def show
      @subscription = Subscription.find(params[:id])
    end

    def new
      @subscription = Subscription.new
    end

    def create
      subscription = Subscription.new(subscription_params)
      @subscription = CreateSubscriptionService.new(subscription).perform!
      if @subscription.valid?
        redirect_to admin_subscriptions_path, notice: 'Inscription créée avec succès !'
      else
        render :new
      end
    end

    def edit
      @subscription = Subscription.find(params[:id])
    end

    def update
      @subscription = Subscription.find(params[:id])
      if @subscription.update(subscription_params)
        @subscription.fee = @subscription.compute_fee
        @subscription.save
        redirect_to admin_subscriptions_path, notice: 'Inscription modifiée avec succès !'
      else
        render :edit
      end
    end

    def destroy
      @subscription = Subscription.find(params[:id])
      @subscription.destroy
      redirect_to admin_subscriptions_path, notice: 'Inscription supprimée avec succès !'
    end

    def unlink_course
      @subscription = Subscription.find(params[:id])
      @course = @subscription.courses.find(params[:course_id])
      @subscription.course_ids -= [@course.id]
      redirect_back fallback_location: root_path, notice: 'Cours retiré avec succès !'
    end

    def confirm
      subscription = Subscription.find(params[:id])
      if subscription.confirmed?
        redirect_to admin_subscriptions_path, alert: "L'inscription est deja confirmée !"
      else
        subscription.confirmed!
        redirect_to admin_subscriptions_path, notice: 'Inscription confirmée avec succès !'
      end
    end

    def archive
      subscription = Subscription.find(params[:id])
      if subscription.archived?
        redirect_to admin_subscriptions_path, alert: "L'inscription est deja archivée !"
      else
        subscription.archived!
        redirect_to admin_subscriptions_path, notice: 'Inscription archivée avec succès !'
      end
    end

    private

    def subscription_params
      params.require(:subscription).permit(:member_id, :status, course_ids: [])
    end
  end
end
