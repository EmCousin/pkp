require 'rails_helper'

describe Subscriptions::Completable, type: :model do
  subject { subscription }

  let(:file) do
    Rack::Test::UploadedFile.new(
      Rails.root.join('spec', 'support', 'file_examples', 'example.svg')
    )
  end

  let(:subscription) { build :subscription }

  it { is_expected.to respond_to :form }

  describe '#completed?' do
    before do
      subscription.update(paid_at: Time.current, payment_method: :cash, doctor_certified_at: Time.current, terms_accepted_at: Time.current)
    end

    it { expect(subscription.completed?).to be true }
  end
end
