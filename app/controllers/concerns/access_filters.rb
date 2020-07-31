# frozen_string_literal: true

module AccessFilters
  extend ActiveSupport::Concern

  included do
    before_action :basic_authenticate, if: :alumni?
    before_action :filter_vacation_time!, if: :vacation_time?, unless: :basic_authenticated?
    before_action :filter_full!, if: :full?
  end

  private

  def basic_authenticate
    if valid_basic_authentication?
      session[:basic_authenticated] = true
    else
      request_http_basic_authentication
    end
  end

  def valid_basic_authentication?
    authenticate_with_http_basic do |u, p|
      u == Rails.application.credentials.basic_auth[:username] && p == Rails.application.credentials.basic_auth[:password]
    end
  end

  def basic_authenticated?
    session[:basic_authenticated] == true
  end

  def filter_vacation_time!
    redirect_to dashboard_vacations_path
  end

  def vacation_time?
    Time.current.month.in?(Course::VACATION_MONTHS)
  end

  def filter_full!
    redirect_to dashboard_capacities_path
  end

  def full?
    Course.available.empty?
  end

  def alumni?
    params[:alumni].present?
  end
end
