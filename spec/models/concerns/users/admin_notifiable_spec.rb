# frozen_string_literal: true

require 'rails_helper'

describe Users::AdminNotifiable, type: :model do
  let(:user) { create :user }

  subject { user }

  context 'when the email changed' do
    let(:email_was) { user.email }
    let(:email) { Faker::Internet.email }

    it 'notifies the admins' do
      expect do
        subject.update!(email: email)
      end.to(
        have_enqueued_job.with(
          'AdminMailer', 'email_changed', 'deliver_now', args: [email_was, email]
        )
      )
    end

    it 'reports an enqueue failure without interrupting the update' do
      delivery = instance_double(ActionMailer::MessageDelivery)
      allow(AdminMailer).to receive(:email_changed).and_return(delivery)
      allow(delivery).to receive(:deliver_later).and_raise('queue unavailable')
      expect(Rails.error).to receive(:report).with(
        instance_of(RuntimeError), handled: true, context: { user_id: user.id }
      )

      expect { subject.update!(email:) }.not_to raise_error
      expect(subject.reload.email).to eq(email)
    end
  end
end
