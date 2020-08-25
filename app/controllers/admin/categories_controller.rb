
module Admin
  class CategoriesController < AdminController
    before_action :set_course, only: %i[show edit update destroy]

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

    def edit; end

    def update
      if @category.update(category_params)
        redirect_to admin_courses_path, notice: t('.success')
      else
        render :edit
      end
    end

    def destroy
      @category.destroy
      redirect_to admin_courses_path, notice: t('.success')
    end

    private

    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:title, :min_age, :max_age)
    end
  end
end
