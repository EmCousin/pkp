# frozen_string_literal: true

module CurrentRequest
  extend ActiveSupport::Concern

  included do
    before_action :set_current_request
  end

  private

  def set_current_request
    Current.request = request
  end
end
