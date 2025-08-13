# frozen_string_literal: true

module Admin
  class CoursesController < BaseController
    before_action :set_course, only: %i[show edit update destroy]
    before_action :set_subscriptions, only: :show
    before_action :filter_available_categories!, only: %i[new], unless: :available_categories?

    def index
      @courses = Course.includes(:subscriptions).order(:weekday, :created_at)
    end

    def show
      session[:admin_course_subscriptions_order] = params[:order] if params[:order].present?
    end

    def new
      @course = Course.new(category_id: params[:category_id])
    end

    def edit; end

    def create
      @course = Course.new(course_params)
      if @course.save
        redirect_to %i[admin courses], notice: t('.success'), status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @course.update(course_params)
        redirect_to %i[admin courses], notice: t('.success'), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @course.destroy
      redirect_to %i[admin courses], notice: t('.success'), status: :see_other
    end

    private

    def filter_available_categories!
      redirect_to new_admin_category_path, notice: t('.create_category')
    end

    def available_categories?
      Category.any?
    end

    def set_course
      @course = Course.find(params[:id])
    end

    def set_subscriptions
      @subscriptions = @course.subscriptions
                              .joins(member: :user)
                              .filter_by_status(params[:status])
                              .where(year: subscription_year)
                              .where(members: { level: subscription_levels })
                              .order(session[:admin_course_subscriptions_order], created_at: :desc)
                              .includes(member: %i[user avatar_attachment])
    end

    def subscription_year
      params[:year].presence || Subscription.current_year
    end

    def subscription_levels
      params[:level].presence || Member.levels.keys
    end

    def course_params
      params.expect(course: %i[title description capacity category_id weekday active features_attendance_sheet])
    end
  end
end
