# frozen_string_literal: true

module Auth
  module Authentication
    extend ActiveSupport::Concern

    included do
      before_action :resume_auth_session
    end

    private

    def authenticate_user!
      return if Current.user

      store_authentication_location
      failure = session.delete(:auth_timed_out) ? 'timeout' : 'unauthenticated'
      redirect_to new_user_session_path,
                  alert: t("auth.failure.#{failure}"),
                  status: :see_other
    end

    def sign_in(user, remember_me: false)
      start_new_auth_session_for(user, remember_me:)
    end

    def sign_out(_user_or_scope = nil)
      Current.user.auth_sessions.where.not(remembered_until: nil).delete_all if Current.user
      terminate_auth_session
    end

    def signed_in_root_path(_scope = nil)
      dashboard_path
    end

    def after_sign_out_path_for(_scope = nil)
      new_user_session_path
    end

    def after_authentication_path
      location = session.delete(:return_to_after_authenticating)
      location.to_s.start_with?('/') && !location.to_s.start_with?('//') ? location : dashboard_path
    end

    def auth_controller?
      controller_path.start_with?('auth/')
    end

    def resume_auth_session
      Current.session ||= find_auth_session_by_cookie
    end

    def find_auth_session_by_cookie
      session_id = cookies.signed[:auth_session_id]
      return if session_id.blank?

      auth_session = Auth::Session.resume(session_id) do |invalid_session|
        session[:auth_timed_out] = true if invalid_session.timed_out?
      end
      cookies.delete(:auth_session_id) unless auth_session
      auth_session
    end

    def store_authentication_location
      session[:return_to_after_authenticating] = request.fullpath if request.request_method == 'GET'
    end

    def start_new_auth_session_for(user, remember_me: false)
      reset_session
      Current.session = user.auth_sessions.create!(auth_session_attributes(remember_me:))
      write_auth_session_cookie(Current.session)
    end

    def auth_session_attributes(remember_me:)
      {
        user_agent: request.user_agent,
        ip_address: request.remote_ip,
        last_seen_at: Time.current,
        remembered_until: (Auth.remember_for.from_now if remember_me)
      }
    end

    def write_auth_session_cookie(auth_session)
      cookie = {
        value: auth_session.id,
        httponly: true,
        same_site: :lax,
        secure: Rails.env.production?
      }
      cookie[:expires] = auth_session.remembered_until if auth_session.remembered_until?
      cookies.signed[:auth_session_id] = cookie
    end

    def terminate_auth_session
      Current.session&.destroy! unless Current.session&.destroyed?
      Current.session = nil
      cookies.delete(:auth_session_id)
      reset_session
    end
  end
end
