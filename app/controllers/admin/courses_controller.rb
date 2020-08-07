# frozen_string_literal: true

module Admin
  class CoursesController < AdminController
    before_action :set_course, only: %i[show edit update destroy]

    def index
      @courses = Course.manageable.includes(:subscriptions).order(:created_at)
    end

    def show; end

    def new
      @course = Course.new
    end

    def create
      @course = Course.new(course_params)
      if @course.save
        redirect_to admin_courses_path, notice: 'Cours créé avec succès !'
      else
        render :new
      end
    end

    def edit; end

    def update
      if @course.update(course_params)
        redirect_to admin_courses_path, notice: 'Cours modifié avec succès !'
      else
        render :edit
      end
    end

    def destroy
      @course.destroy
      redirect_to admin_courses_path, notice: 'Cours supprimé avec succès !'
    end

    private

    def set_course
      @course = Course.find(params[:id])
    end

    def course_params
      params.require(:course).permit(:title, :description, :capacity, :category, :weekday, :active)
    end
  end
end
