# frozen_string_literal: true

module AccessFilters
  extend ActiveSupport::Concern

  included do
    before_action :filter_vacation_time!, if: :vacation_time?, unless: :alumni_authenticated?
    before_action :filter_full!, if: :full?
  end

  private

  def alumni_authenticated?
    session[:alumni_authenticated] == true
  end

  def filter_vacation_time!
    redirect_to dashboard_vacation_path
  end

  def filter_full!
    redirect_to dashboard_capacity_path
  end
end
