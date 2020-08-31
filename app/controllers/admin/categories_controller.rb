# frozen_string_literal: true

module Admin
  class CategoriesController < AdminController
    def new
      @category = Category.new
    end

    def create
      @category = Category.new(category_params)
      if @category.save
        redirect_to new_admin_course_path(category_id: @category.id), notice: t('.success')
      else
        render :new
      end
    end

    private

    def category_params
      params.require(:category).permit(:title, :min_age, :max_age)
    end
  end
end
