# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
describe 'Authentication', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:password) { 'surprise' }
  let(:user) { create(:user, password:) }

  describe 'sessions' do
    it 'signs in with a normalized email and preserves a protected destination' do
      get dashboard_members_path
      expect(response).to redirect_to(new_user_session_path)

      post user_session_path, params: { user: { email: "  #{user.email.upcase} ", password: } }

      expect(response).to redirect_to(dashboard_members_path)
      expect(user.auth_sessions.count).to eq(1)
    end

    it 'does not preserve a HEAD request as a browser destination' do
      head dashboard_members_path

      post user_session_path, params: { user: { email: user.email, password: } }

      expect(response).to redirect_to(dashboard_path)
    end

    it 'uses a generic error for invalid credentials' do
      post user_session_path, params: { user: { email: user.email, password: 'incorrect' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('E-mail ou mot de passe incorrect')
      expect(user.reload.failed_attempts).to eq(1)
    end

    it 'creates a two-week remembered session when requested' do
      freeze_time do
        post user_session_path, params: { user: { email: user.email, password:, remember_me: '1' } }

        expect(user.auth_sessions.last.remembered_until).to be_within(1.second).of(2.weeks.from_now)
      end
    end

    it 'locks an account on its twentieth failed attempt and unlocks it after ten minutes' do
      user.update_column(:failed_attempts, Auth.maximum_attempts - 1) # rubocop:disable Rails/SkipsModelValidations
      previous_session = user.auth_sessions.create!(last_seen_at: Time.current)

      perform_enqueued_jobs(only: Auth::SendUnlockInstructionsJob) do
        post user_session_path, params: { user: { email: user.email, password: 'incorrect' } }
      end

      expect(user.reload).to be_access_locked
      expect(ActionMailer::Base.deliveries.last.to).to contain_exactly(user.email)
      expect(user.authentication_generation).not_to eq(0)
      expect(Auth::Session).not_to exist(previous_session.id)

      post user_session_path, params: { user: { email: user.email, password: } }
      expect(response).to have_http_status(:unprocessable_content)

      travel Auth.unlock_in + 1.minute do
        post user_session_path, params: { user: { email: user.email, password: } }
        expect(response).to redirect_to(dashboard_path)
      end
    end

    it 'expires an inactive session and reports the timeout' do
      sign_in user
      user.auth_sessions.update_all(last_seen_at: 8.days.ago) # rubocop:disable Rails/SkipsModelValidations

      get dashboard_path

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to eq(I18n.t('auth.failure.timeout'))
    end

    it 'signs out through a DELETE form' do
      sign_in user

      delete destroy_user_session_path

      expect(response).to redirect_to(new_user_session_path)
      expect(user.auth_sessions.reload).to be_empty
    end

    it 'renders the sign-in page at the public root and the dashboard at the authenticated root' do
      get root_path
      expect(response.body).to include(I18n.t('defaults.login'))

      sign_in user
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t('layouts.navbar.my_members'))
    end
  end

  describe 'registrations' do
    let(:registration_params) do
      {
        first_name: 'Camille',
        last_name: 'Martin',
        email: 'camille@example.com',
        email_confirmation: 'camille@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        terms_of_service: '1'
      }
    end

    it 'creates and signs in a user' do
      expect do
        post user_registration_path, params: { user: registration_params }
      end.to change(User, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
      expect(User.find_by!(email: 'camille@example.com').auth_sessions.count).to eq(1)
    end

    it 'requires matching email confirmation on the server' do
      expect do
        post user_registration_path, params: { user: registration_params.except(:email_confirmation) }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'rejects email providers that block platform mail' do
      blocked_params = registration_params.merge(
        email: 'camille@orange.fr',
        email_confirmation: 'camille@orange.fr'
      )

      expect do
        post user_registration_path, params: { user: blocked_params }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'does not persist account changes when the current password is wrong' do
      sign_in user

      put user_registration_path, params: { user: { first_name: 'Changed', current_password: 'wrong' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.first_name).not_to eq('Changed')
    end

    it 'updates the password and rotates the current session' do
      sign_in user
      original_session = user.auth_sessions.first

      put user_registration_path, params: {
        user: {
          password: 'new-password',
          password_confirmation: 'new-password',
          current_password: password
        }
      }

      expect(response).to redirect_to(dashboard_path)
      expect(user.reload).to be_valid_password('new-password')
      expect(user.auth_sessions.count).to eq(1)
      expect(user.auth_sessions.first).not_to eq(original_session)
    end

    it 'rechecks the current password after locking a stale user instance' do
      stale_user = User.find(user.id)
      user.update!(password: 'replacement-password', password_confirmation: 'replacement-password')

      expect(stale_user.update_account(
               { password: 'stale-password', password_confirmation: 'stale-password' },
               current_password: password
             )).to be(false)
      expect(user.reload).to be_valid_password('replacement-password')
    end

    it 'uses a server-rendered account deletion confirmation' do
      sign_in user

      get delete_user_registration_path

      form = response.parsed_body.at_css("form[action='#{user_registration_path}']")
      expect(form).to be_present
      expect(form.at_css("input[name='_method'][value='delete']")).to be_present
    end
  end

  describe 'password resets' do
    it 'returns the same response for known and unknown email addresses' do
      perform_enqueued_jobs(only: Auth::SendResetPasswordInstructionsJob) do
        post user_password_path, params: { user: { email: user.email } }
      end
      known_response = [response.status, flash[:notice]]

      expect do
        post user_password_path, params: { user: { email: 'unknown@example.com' } }
      end.to have_enqueued_job(Auth::SendResetPasswordInstructionsJob).with('unknown@example.com')

      expect([response.status, flash[:notice]]).to eq(known_response)
      expect(ActionMailer::Base.deliveries.last.to).to contain_exactly(user.email)
    end

    it 'surfaces a failure to enqueue reset instructions' do
      allow(Auth::SendResetPasswordInstructionsJob).to receive(:perform_later)
        .and_raise(ActiveJob::EnqueueError, 'queue unavailable')

      expect do
        post user_password_path, params: { user: { email: user.email } }
      end.to raise_error(ActiveJob::EnqueueError, 'queue unavailable')
    end

    it 'rate limits repeated reset requests' do
      headers = { 'REMOTE_ADDR' => '192.0.2.10' }
      Rails.cache.delete('rate-limit:auth/passwords:192.0.2.10')

      Auth.recovery_request_limit.times do
        post user_password_path, params: { user: { email: 'unknown@example.com' } }, headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end

      post user_password_path, params: { user: { email: 'unknown@example.com' } }, headers: headers

      expect(response).to have_http_status(:too_many_requests)
    end

    it 'keeps previously sent reset instructions valid' do
      first_token = user.send_reset_password_instructions
      user.send_reset_password_instructions

      expect(User.from_reset_password_token(first_token)).to eq(user)
    end

    it 'can retry reset instruction delivery after a mail failure' do
      message = instance_double(ActionMailer::MessageDelivery)
      allow(Auth::Mailer).to receive(:reset_password_instructions).and_return(message)
      allow(message).to receive(:deliver_now).and_raise(Net::SMTPServerBusy, 'mail unavailable')

      expect { user.send_reset_password_instructions }.to raise_error(Net::SMTPServerBusy)
      allow(message).to receive(:deliver_now).and_return(true)
      expect(user.send_reset_password_instructions).to be_present
    end

    it 'changes the password, unlocks the account, and signs the user in' do
      token = user.send_reset_password_instructions
      user.update_columns(locked_at: Time.current, failed_attempts: Auth.maximum_attempts) # rubocop:disable Rails/SkipsModelValidations

      put user_password_path, params: {
        user: {
          reset_password_token: token,
          password: 'new-password',
          password_confirmation: 'new-password'
        }
      }

      expect(response).to redirect_to(dashboard_path)
      expect(user.reload).to be_valid_password('new-password')
      expect(user).not_to be_access_locked
      expect(user.auth_sessions.count).to eq(1)
    end

    it 'rejects an expired reset token' do
      token = user.send_reset_password_instructions

      travel Auth.reset_password_within + 1.second do
        get edit_user_password_path(reset_password_token: token)
      end

      expect(response).to redirect_to(new_user_password_path)
    end

    it 'rejects a modified reset token' do
      token = user.send_reset_password_instructions

      get edit_user_password_path(reset_password_token: "#{token}modified")

      expect(response).to redirect_to(new_user_password_path)
    end

    it 'requires a nonblank password and confirmation' do
      token = user.send_reset_password_instructions

      put user_password_path, params: {
        user: { reset_password_token: token, password: '', password_confirmation: '' }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload).to be_valid_password(password)
      expect(User.from_reset_password_token(token)).to eq(user)
      expect(user.auth_sessions).to be_empty
    end

    it 'invalidates a reset link when the password changes' do
      token = user.send_reset_password_instructions
      user.update!(password: 'replacement-password', password_confirmation: 'replacement-password')

      get edit_user_password_path(reset_password_token: token)

      expect(response).to redirect_to(new_user_password_path)
    end

    it 'invalidates a reset link when the email changes' do
      token = user.send_reset_password_instructions
      user.update!(email: 'replacement@example.com')

      get edit_user_password_path(reset_password_token: token)

      expect(response).to redirect_to(new_user_password_path)
    end

    it 'consumes a reset token only once across stale user instances' do
      token = user.send_reset_password_instructions
      stale_user = User.find(user.id)

      expect(user.reset_password(
               token:,
               password: 'first-password',
               password_confirmation: 'first-password'
             )).to be(true)
      expect(stale_user.reset_password(
               token:,
               password: 'second-password',
               password_confirmation: 'second-password'
             )).to be(false)
      expect(user.reload).to be_valid_password('first-password')
    end
  end

  describe 'unlocks' do
    it 'unlocks an account from its emailed token' do
      user.update_columns(locked_at: Time.current, failed_attempts: Auth.maximum_attempts) # rubocop:disable Rails/SkipsModelValidations
      token = user.send_unlock_instructions

      get user_unlock_path(unlock_token: token)

      expect(response).to redirect_to(new_user_session_path)
      expect(user.reload).not_to be_access_locked
    end

    it 'surfaces a failure to enqueue unlock instructions' do
      allow(Auth::SendUnlockInstructionsJob).to receive(:perform_later)
        .and_raise(ActiveJob::EnqueueError, 'queue unavailable')

      expect do
        post user_unlock_path, params: { user: { email: user.email } }
      end.to raise_error(ActiveJob::EnqueueError, 'queue unavailable')
    end

    it 'rate limits repeated unlock requests' do
      headers = { 'REMOTE_ADDR' => '192.0.2.11' }
      Rails.cache.delete('rate-limit:auth/unlocks:192.0.2.11')

      Auth.recovery_request_limit.times do
        post user_unlock_path, params: { user: { email: 'unknown@example.com' } }, headers: headers
        expect(response).to redirect_to(new_user_session_path)
      end

      post user_unlock_path, params: { user: { email: 'unknown@example.com' } }, headers: headers

      expect(response).to have_http_status(:too_many_requests)
    end

    it 'keeps previously sent unlock instructions valid' do
      user.update_columns(locked_at: Time.current, failed_attempts: Auth.maximum_attempts) # rubocop:disable Rails/SkipsModelValidations
      first_token = user.send_unlock_instructions
      user.send_unlock_instructions

      expect(User.unlock_by_token(first_token)).to eq(user)
    end

    it 'can retry unlock instruction delivery after a mail failure' do
      user.update_columns(locked_at: Time.current, failed_attempts: Auth.maximum_attempts) # rubocop:disable Rails/SkipsModelValidations
      message = instance_double(ActionMailer::MessageDelivery)
      allow(Auth::Mailer).to receive(:unlock_instructions).and_return(message)
      allow(message).to receive(:deliver_now).and_raise(Net::SMTPServerBusy, 'mail unavailable')

      expect { user.send_unlock_instructions }.to raise_error(Net::SMTPServerBusy)
      allow(message).to receive(:deliver_now).and_return(true)
      expect(user.send_unlock_instructions).to be_present
    end

    it 'rejects a modified unlock token' do
      user.update_columns(locked_at: Time.current, failed_attempts: Auth.maximum_attempts) # rubocop:disable Rails/SkipsModelValidations
      token = user.send_unlock_instructions

      get user_unlock_path(unlock_token: "#{token}modified")

      expect(response).to redirect_to(new_user_unlock_path)
      expect(user.reload).to be_access_locked
    end

    it 'does not disclose whether an account exists' do
      expect do
        post user_unlock_path, params: { user: { email: 'unknown@example.com' } }
      end.to have_enqueued_job(Auth::SendUnlockInstructionsJob).with('unknown@example.com')

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:notice]).to eq(I18n.t('auth.unlocks.create.success'))
    end
  end
end
# rubocop:enable Metrics/BlockLength
