# frozen_string_literal: true

module Admin
  class CoursesController < AdminController
    before_action :set_course, only: %i[show edit update destroy]
    before_action :filter_available_categories!, only: %i[new], unless: :available_categories?

    def index
      @courses = Course.includes(:subscriptions).order(:created_at)
    end

    def show; end

    def new
      @course = Course.new(category_id: params[:category_id])
    end

    def create
      @course = Course.new(course_params)
      if @course.save
        redirect_to admin_courses_path, notice: t('.success'), status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @course.update(course_params)
        redirect_to admin_courses_path, notice: t('.success')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @course.destroy
      redirect_to admin_courses_path, notice: t('.success')
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

    def course_params
      params.require(:course).permit(:title, :description, :capacity, :category_id, :weekday, :active)
    end
  end
end
