# frozen_string_literal: true

module Admin
  class CampsController < BaseController
    before_action :set_camp, only: %i[show edit update destroy]
    before_action :set_subscriptions, only: :show

    def index
      @camps = current_platform.camps.includes(:subscriptions).order(:starts_at, :created_at)
    end

    def show
      session[:admin_camp_subscriptions_order] = params[:order] if params[:order].present?
    end

    def new
      @camp = current_platform.camps.new
    end

    def edit; end

    def create
      @camp = current_platform.camps.new(camp_params)
      if @camp.save
        redirect_back_or_to [:admin, @camp], notice: t('.success'), status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @camp.update(camp_params)
        redirect_to admin_camp_path(@camp, success: true), notice: t('.success'), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @camp.destroy
        redirect_back_or_to %i[admin camps], notice: t('.success'), status: :see_other
      else
        redirect_back_or_to %i[admin camps], alert: t('.error'), status: :see_other
      end
    end

    private

    def set_camp
      @camp = current_platform.camps.find(params[:id])
    end

    def set_subscriptions
      @subscriptions = @camp.subscriptions
                            .joins(member: :user)
                            .filter_by_status(params[:status])
                            .order(session[:admin_camp_subscriptions_order], created_at: :desc)
                            .includes(member: %i[user avatar_attachment])
    end

    def camp_params
      params.expect(camp: %i[title description capacity starts_at ends_at price external_price active open open_to_externals cover_picture])
    end
  end
end
