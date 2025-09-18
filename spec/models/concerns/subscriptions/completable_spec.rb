require 'rails_helper'

describe Subscriptions::Completable, type: :model do
  subject { subscription }

  let(:file) do
    Rack::Test::UploadedFile.new(
      Rails.root.join('spec', 'support', 'file_examples', 'avatar.jpg')
    )
  end

  let(:subscription) { build :subscription }

  it { is_expected.to respond_to :form }

  describe '#completed?' do
    before do
      subscription.update(paid_at: Time.current, payment_method: :cash, doctor_certified_at: Time.current, terms_accepted_at: Time.current, medical_certificate: file)
    end

    it { expect(subscription.completed?).to be true }

    context 'when terms are not accepted' do
      before do
        subscription.update(terms_accepted_at: nil)
      end

      it { expect(subscription.completed?).to be false }
    end

    context 'when doctor is not certified' do
      before do
        subscription.update(doctor_certified_at: nil)
      end

      it { expect(subscription.completed?).to be false }
    end

    context 'when medical certificate is not attached' do
      before do
        subscription.update(medical_certificate: nil)
      end

      it { expect(subscription.completed?).to be false }
    end

    context 'when payment is not done' do
      before do
        subscription.update(paid_at: nil)
      end

      it { expect(subscription.completed?).to be false }
    end
  end
end
