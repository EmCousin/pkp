# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
describe Subscriptions::MedicalCertificate, type: :model do
  subject(:medical_certificate) { described_class.new(subscription:) }

  let(:file) do
    Rack::Test::UploadedFile.new(
      Rails.root.join('spec/support/file_examples/avatar.jpg')
    )
  end
  let(:platform) { create(:platform, medical_certificate_validity_seasons: 3) }
  let(:member) { create(:member, platform:) }
  let(:course) { create(:course, category: create(:category, platform:, title: 'Adulte')) }
  let(:current_year) { 2026 }
  let(:subscription) do
    create(:subscription, member:, courses: [course], year: current_year)
  end

  def create_source(year, **attributes)
    create(
      :subscription,
      {
        member:,
        courses: [course],
        year:,
        doctor_certified_at: Time.current,
        medical_certificate: file
      }.merge(attributes)
    )
  end

  it 'uses the subscription own certificate first' do
    subscription.update!(doctor_certified_at: Time.current, medical_certificate: file)
    create_source(current_year - 1)

    expect(medical_certificate).to be_valid
    expect(medical_certificate.source).to eq(subscription)
    expect(medical_certificate).not_to be_inherited
    expect(medical_certificate.attachment).to be_attached
  end

  it 'uses the most recent certificate within the validity period' do
    create_source(current_year - 2)
    recent_source = create_source(current_year - 1)

    expect(medical_certificate).to be_valid
    expect(medical_certificate.source).to eq(recent_source)
    expect(medical_certificate).to be_inherited
  end

  it 'rejects a certificate outside the validity period' do
    create_source(current_year - 3)

    expect(medical_certificate).not_to be_valid
    expect(medical_certificate.source).to be_nil
  end

  it 'uses the configured validity period' do
    platform.update!(medical_certificate_validity_seasons: 2)
    create_source(current_year - 2)

    expect(medical_certificate).not_to be_valid
  end

  it 'keeps archived certificate sources valid' do
    source = create_source(current_year - 1, status: :archived)

    expect(medical_certificate.source).to eq(source)
  end

  it 'detects when a later subscription relies on the source' do
    source = create_source(current_year - 1)
    subscription

    expect(described_class.new(subscription: source)).to be_source_in_use
  end

  it 'does not retain a result between validation objects' do
    expect(medical_certificate).not_to be_valid

    subscription.update!(doctor_certified_at: Time.current, medical_certificate: file)

    expect(described_class.new(subscription:)).to be_valid
  end
end
# rubocop:enable Metrics/BlockLength
