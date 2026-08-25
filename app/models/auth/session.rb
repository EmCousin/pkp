# frozen_string_literal: true

module Auth
  class Session < ApplicationRecord
    self.table_name = 'auth_sessions'

    INACTIVITY_TIMEOUT = 1.week
    REMEMBER_FOR = 2.weeks
    LAST_SEEN_TOUCH_INTERVAL = 1.minute

    belongs_to :user, inverse_of: :auth_sessions

    before_validation :copy_authentication_generation, on: :create

    scope :expired, lambda {
      where(remembered_until: ..Time.current)
        .or(where(remembered_until: nil, last_seen_at: ...INACTIVITY_TIMEOUT.ago))
    }

    def self.resume(id)
      return if id.blank?

      session = includes(:user).find_by(id:)
      return unless session

      session.user.unlock_if_expired!
      return session.tap(&:touch_last_seen!) if session.resumable?

      yield session if block_given?
      session.destroy!
      nil
    end

    def resumable?
      return false if authentication_generation != user.authentication_generation
      return false if user.access_locked?
      return remembered_until.future? if remembered_until?

      last_seen_at.after?(INACTIVITY_TIMEOUT.ago)
    end

    def timed_out?
      return !remembered_until.future? if remembered_until?

      last_seen_at.before?(INACTIVITY_TIMEOUT.ago)
    end

    def touch_last_seen!
      return unless last_seen_at.before?(LAST_SEEN_TOUCH_INTERVAL.ago)

      update!(last_seen_at: Time.current)
    end

    private

    def copy_authentication_generation
      self.authentication_generation = user.authentication_generation
    end
  end
end
