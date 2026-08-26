# frozen_string_literal: true

module Auth
  class Session < ApplicationRecord
    belongs_to :user

    before_validation :copy_authentication_credentials, on: :create

    scope :expired, lambda {
      where(remembered_until: ..Time.current)
        .or(where(remembered_until: nil, last_seen_at: ...Auth.inactivity_timeout.ago))
    }

    def self.resume(id)
      return if id.blank?

      return unless (session = find_by(id:))

      session.user.unlock_if_expired!
      if session.resumable?
        session.touch_last_seen!
        return session
      end

      yield session if block_given?
      session.destroy!
      nil
    end

    def resumable?
      return false if authentication_generation != user.authentication_generation
      return false if credential_fingerprint != user.authentication_fingerprint
      return false if user.access_locked?
      return remembered_until.future? if remembered_until?

      last_seen_at.after?(Auth.inactivity_timeout.ago)
    end

    def timed_out?
      return !remembered_until.future? if remembered_until?

      last_seen_at.before?(Auth.inactivity_timeout.ago)
    end

    def touch_last_seen!
      return unless last_seen_at.before?(Auth.last_seen_touch_interval.ago)

      update!(last_seen_at: Time.current)
    end

    private

    def copy_authentication_credentials
      self.authentication_generation = user.authentication_generation
      self.credential_fingerprint = user.authentication_fingerprint
    end
  end
end
