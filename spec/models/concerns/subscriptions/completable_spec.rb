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
  it { is_expected.to respond_to :signed_form }
  it { is_expected.to respond_to :medical_certificate }

  describe '#completed?' do
    before do
      allow(subscription).to receive(:paid?).and_return true
      subscription.signed_form.attach(file)
      subscription.medical_certificate.attach(file)
    end

    it { expect(subscription.completed?).to be true }
  end
end
