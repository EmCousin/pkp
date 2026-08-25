# frozen_string_literal: true

module Auth
  module RequestHelpers
    def sign_in(user)
      @auth_session = Current.session = user.auth_sessions.create!(last_seen_at: Time.current)
      cookies.delete('auth_session_id')
      cookies.merge("auth_session_id=#{Rack::Utils.escape(signed_auth_cookie)}", URI.parse("http://#{host}"))
    end

    def sign_out(_scope = nil)
      @auth_session&.destroy!
      @auth_session = nil
      Current.session = nil
      cookies.delete('auth_session_id')
    end

    private

    def signed_auth_cookie
      ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
        cookie_jar.signed[:auth_session_id] = Current.session.id
      end[:auth_session_id]
    end
  end
end

RSpec.configure do |config|
  config.include Auth::RequestHelpers, type: :request
end
