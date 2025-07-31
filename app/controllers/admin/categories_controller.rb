# frozen_string_literal: true

module Admin
  class CategoriesController < BaseController
    def new
      @category = Category.new
    end

    def create
      @category = Category.new(category_params)
      if @category.save
        redirect_to new_admin_course_path(category_id: @category.id), notice: t('.success'), status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def category_params
      params.expect(category: %i[title min_age max_age])
    end
  end
end
