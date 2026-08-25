# frozen_string_literal: true

require 'rails_helper'

describe Auth::Session, type: :model do # rubocop:disable Metrics/BlockLength
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  it 'resumes an active session' do
    auth_session = create_session(last_seen_at: 2.days.ago)

    expect(described_class.resume(auth_session.id)).to eq(auth_session)
  end

  it 'expires a session after one week of inactivity' do
    auth_session = create_session(last_seen_at: 8.days.ago)

    expect(described_class.resume(auth_session.id)).to be_nil
    expect(described_class).not_to exist(auth_session.id)
  end

  it 'keeps a remembered session active despite inactivity' do
    auth_session = create_session(last_seen_at: 8.days.ago, remembered_until: 1.day.from_now)

    expect(described_class.resume(auth_session.id)).to eq(auth_session)
  end

  it 'rejects an active session after the account is locked' do
    auth_session = create_session(last_seen_at: Time.current)
    user.update_columns(locked_at: Time.current, failed_attempts: User::MAXIMUM_AUTHENTICATION_ATTEMPTS) # rubocop:disable Rails/SkipsModelValidations

    expect(described_class.resume(auth_session.id)).to be_nil
  end

  it 'rejects a session created from stale credentials' do
    stale_user = User.find(user.id)
    user.update!(password: 'replacement-password', password_confirmation: 'replacement-password')
    auth_session = stale_user.auth_sessions.create!(last_seen_at: Time.current)

    expect(auth_session.authentication_generation).to eq(0)
    expect(described_class.resume(auth_session.id)).to be_nil
  end

  it 'rejects a session after the previous Devise release changes the password' do
    auth_session = create_session(last_seen_at: Time.current)
    legacy_hash = BCrypt::Password.create('legacy-password')
    user.update_column(:encrypted_password, legacy_hash) # rubocop:disable Rails/SkipsModelValidations

    expect(described_class.resume(auth_session.id)).to be_nil
  end

  it 'rejects a session after the previous Devise release locks and unlocks the user' do
    auth_session = create_session(last_seen_at: Time.current)
    user.update_column(:locked_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
    user.update_columns(locked_at: nil, failed_attempts: 0, unlock_token: nil) # rubocop:disable Rails/SkipsModelValidations

    expect(described_class.resume(auth_session.id)).to be_nil
  end

  it 'is deleted when the previous release deletes its user without callbacks' do
    auth_session = create_session(last_seen_at: Time.current)

    User.where(id: user.id).delete_all

    expect(described_class).not_to exist(auth_session.id)
  end

  it 'prunes expired normal and remembered sessions' do
    expired_normal = create_session(last_seen_at: 8.days.ago)
    expired_remembered = create_session(last_seen_at: Time.current, remembered_until: 1.minute.ago)
    active = create_session(last_seen_at: Time.current)

    Auth::PruneSessionsJob.perform_now

    expect(described_class.where(id: [expired_normal.id, expired_remembered.id])).to be_empty
    expect(described_class).to exist(active.id)
  end

  def create_session(attributes)
    user.auth_sessions.create!(attributes)
  end
end # rubocop:enable Metrics/BlockLength
