# frozen_string_literal: true

module Admin
  class CampsController < BaseController
    before_action :set_camp, only: %i[show edit update destroy]
    before_action :set_subscriptions, only: :show

    def index
      @camps = Camp.includes(:subscriptions).order(:starts_at, :created_at)
    end

    def show
      session[:admin_camp_subscriptions_order] = params[:order] if params[:order].present?
    end

    def new
      @camp = Camp.new
    end

    def edit; end

    def create
      @camp = Camp.new(camp_params)
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
      @camp.destroy
      redirect_back_or_to %i[admin camps], notice: t('.success'), status: :see_other
    end

    private

    def set_camp
      @camp = Camp.find(params[:id])
    end

    def set_subscriptions
      @subscriptions = @camp.subscriptions
                            .joins(member: :user)
                            .filter_by_status(params[:status])
                            .order(session[:admin_camp_subscriptions_order], created_at: :desc)
                            .includes(member: %i[user avatar_attachment])
    end

    def camp_params
      params.expect(camp: %i[title description capacity starts_at ends_at price active open cover_picture])
    end
  end
end
