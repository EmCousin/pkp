require 'rails_helper'

describe Users::AdminNotifiable, type: :model do
  let(:user) { create :user }

  subject { user }

  context 'when the email changed' do
    let(:email_was) { user.email }
    let(:email) { Faker::Internet.email }

    it 'notifies the admins' do
      expect {
        subject.update!(email: email)
      }.to(
        have_enqueued_job.with(
          'AdminMailer', 'email_changed', 'deliver_now', args: [email_was, email]
        )
      )
    end
  end
end
