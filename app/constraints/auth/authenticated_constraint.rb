# frozen_string_literal: true

module Auth
  class AuthenticatedConstraint
    def initialize(&user_requirement)
      @user_requirement = user_requirement
    end

    def matches?(request)
      user = auth_session(request)&.user
      user.present? && (!user_requirement || user_requirement.call(user))
    end

    private

    attr_reader :user_requirement

    def auth_session(request)
      Auth::Session.resume(request.cookie_jar.signed[:auth_session_id])
    end
  end
end
