# frozen_string_literal: true

module Admin
  class CategoriesController < BaseController
    before_action :set_category, only: %i[show edit update destroy]

    def index
      @categories = Category.order(:title)
    end

    def show; end

    def new
      @category = Category.new
      @category.pricings.build
    end

    def edit; end

    def create
      @category = Category.new(category_params)
      if @category.save
        redirect_to [:admin, @category], notice: t('.success'), status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @category.update(category_params)
        redirect_to admin_category_path(@category, success: true), notice: t('.success'), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @category.destroy
        redirect_back_or_to %i[admin categories], notice: t('.success'), status: :see_other
      else
        redirect_back_or_to %i[admin categories], alert: @category.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def category_params
      params.expect(category: [
                      :title,
                      :min_age,
                      :max_age,
                      { pricings_attributes: [%i[id name prices_string starts_at ends_at _destroy]] }
                    ])
    end

    def set_category
      @category = Category.find(params[:id])
    end
  end
end
