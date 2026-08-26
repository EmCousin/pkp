# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :request, :domain, :platform, :session

  delegate :user, to: :session, allow_nil: true

  def request=(request)
    super
    self.domain = request.domain.to_s.downcase
  end
end
