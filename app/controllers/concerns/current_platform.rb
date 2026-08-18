# frozen_string_literal: true

module CurrentPlatform
  extend ActiveSupport::Concern

  included do
    before_action :set_current_platform
  end

  private

  def set_current_platform
    Current.platform = Platform.find_by!(domain: Current.domain)
  end
end
