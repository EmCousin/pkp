# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
describe Subscriptions::Confirmable, type: :model do
  let(:file) do
    Rack::Test::UploadedFile.new(Rails.root.join('spec/support/file_examples/avatar.jpg'))
  end
  let(:subscription) do
    create(
      :subscription,
      courses: [create(:course)],
      terms_accepted_at: Time.current,
      doctor_certified_at: Time.current,
      medical_certificate: file,
      medical_certificate_validated_at: Time.current,
      paid_at: Time.current,
      payment_method: :cash
    )
  end

  describe '#confirm!' do
    it 'confirms a pending subscription and sends the confirmation email' do
      expect { subscription.confirm! }.to have_enqueued_mail(SubscriptionMailer, :confirm_subscription)
      expect(subscription).to be_confirmed
    end

    it 'does not resend the confirmation email when the subscription is already confirmed' do
      subscription.confirm!

      expect { subscription.confirm! }.not_to have_enqueued_mail(SubscriptionMailer, :confirm_subscription)
      expect(subscription).to be_confirmed
    end

    it 'is a no-op for an archived subscription' do
      subscription.archived!

      expect { subscription.confirm! }.not_to have_enqueued_mail(SubscriptionMailer, :confirm_subscription)
      expect(subscription.reload).to be_archived
    end
  end
end
# rubocop:enable Metrics/BlockLength
