# frozen_string_literal: true

require 'rails_helper'

describe Subscriptions::Completable, type: :model do
  subject { subscription }

  let(:file) do
    Rack::Test::UploadedFile.new(
      Rails.root.join('spec', 'support', 'file_examples', 'avatar.jpg')
    )
  end

  let(:platform) { create(:platform, medical_certificate_validity_seasons: 3) }
  let(:member) { create(:member, platform:) }
  let(:course) { create(:course, category: create(:category, platform:, title: 'Adulte')) }
  let(:subscription) { build(:subscription, member:) }

  it { is_expected.to respond_to :form }

  describe '#completed?' do
    before do
      subscription.update(
        paid_at: Time.current,
        payment_method: :cash,
        doctor_certified_at: Time.current,
        terms_accepted_at: Time.current,
        medical_certificate: file
      )
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

  describe 'medical certificate validity' do
    let(:current_year) { 2026 }
    let(:subscription) do
      create(
        :subscription,
        member:,
        courses: [course],
        year: current_year,
        paid_at: Time.current,
        payment_method: :cash,
        terms_accepted_at: Time.current
      )
    end

    def create_certificate_source(year)
      create(
        :subscription,
        member:,
        courses: [course],
        year:,
        doctor_certified_at: Time.current,
        medical_certificate: file
      )
    end

    it 'uses a certificate uploaded two seasons earlier' do
      source = create_certificate_source(current_year - 2)

      expect(subscription.medical_certificate_source).to eq(source)
      expect(subscription.effective_medical_certificate).to be_attached
      expect(subscription).to be_inherited_medical_certificate
      expect(subscription.medical_certificate).not_to be_attached
      expect(subscription).to be_completed
    end

    it 'does not use a certificate uploaded three seasons earlier' do
      create_certificate_source(current_year - 3)

      expect(subscription).not_to be_medical_certificate_valid
      expect(subscription).not_to be_completed
    end

    it 'uses the configured number of consecutive seasons' do
      platform.update!(medical_certificate_validity_seasons: 2)
      create_certificate_source(current_year - 2)

      expect(subscription).not_to be_medical_certificate_valid
    end

    it 'uses the most recent valid certificate as the new source' do
      create_certificate_source(current_year - 2)
      recent_source = create_certificate_source(current_year - 1)

      expect(subscription.medical_certificate_source).to eq(recent_source)
    end

    it 'rechecks validity after the certificate changes on the same instance' do
      expect(subscription).not_to be_medical_certificate_valid

      subscription.update!(doctor_certified_at: Time.current, medical_certificate: file)

      expect(subscription).to be_medical_certificate_valid
    end

    it 'keeps an archived certificate source valid' do
      source = create_certificate_source(current_year - 2)
      source.archived!

      expect(subscription.medical_certificate_source).to eq(source)
    end

    it 'prevents deletion while a later subscription uses the certificate' do
      source = create_certificate_source(current_year - 2)
      subscription

      expect(source.destroy).to be false
      expect(source.errors.of_kind?(:base, :medical_certificate_in_use)).to be true
      expect(source).to be_persisted
      expect(subscription.reload).to be_medical_certificate_valid
    end

    it 'allows deletion when a later subscription has its own certificate' do
      source = create_certificate_source(current_year - 2)
      subscription.update!(doctor_certified_at: Time.current, medical_certificate: file)

      expect(source.destroy).to eq(source)
      expect(source).not_to be_persisted
    end

    it 'allows the member and all subscriptions to be deleted together' do
      create_certificate_source(current_year - 2)
      create(:subscription, member:, courses: [course], year: current_year)

      expect(member.destroy).to eq(member)
      expect(member).not_to be_persisted
      expect(Subscription.where(member_id: member.id)).to be_empty
    end
  end
end
