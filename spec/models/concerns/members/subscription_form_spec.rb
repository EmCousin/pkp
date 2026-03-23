# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Members::SubscriptionForm do
  let(:member) { create(:member) }
  let(:category) { create(:category) }
  let!(:pricing) { create(:pricing, category:) }
  let(:course) { create(:course, category:) }
  let(:subscription) { create(:subscription, member:, courses: [course], status: :confirmed) }

  describe '#clear_subscription_forms' do
    before do
      subscription.form.attach(
        io: StringIO.new('dummy pdf content'),
        filename: 'form.pdf',
        content_type: 'application/pdf'
      )
      subscription.reload
    end

    context 'when relevant attributes change' do
      it 'clears attached form when first_name changes' do
        expect { member.update!(first_name: 'NewName') }
          .to change { subscription.reload.form.attached? }.from(true).to(false)
      end

      it 'clears attached form when last_name changes' do
        expect { member.update!(last_name: 'NewName') }
          .to change { subscription.reload.form.attached? }.from(true).to(false)
      end

      it 'clears attached form when birthdate changes' do
        expect { member.update!(birthdate: 5.years.ago.to_date) }
          .to change { subscription.reload.form.attached? }.from(true).to(false)
      end

      it 'clears attached form when contact_name changes' do
        expect { member.update!(contact_name: 'New Contact') }
          .to change { subscription.reload.form.attached? }.from(true).to(false)
      end

      it 'clears attached form when contact_phone_number changes' do
        expect { member.update!(contact_phone_number: '06 12 34 56 78') }
          .to change { subscription.reload.form.attached? }.from(true).to(false)
      end

      it 'clears attached form when contact_relationship changes' do
        expect { member.update!(contact_relationship: 'Mère') }
          .to change { subscription.reload.form.attached? }.from(true).to(false)
      end
    end

    context 'when irrelevant attributes change' do
      it 'does not clear form when level changes' do
        expect { member.update!(level: :yellow) }
          .not_to change { subscription.reload.form.attached? }
      end

      it 'does not clear form when avatar changes' do
        new_avatar = fixture_file_upload('avatar.jpg', 'image/jpeg')
        expect { member.update!(avatar: new_avatar) }
          .not_to change { subscription.reload.form.attached? }
      end
    end

    context 'when multiple subscriptions have forms' do
      let(:course2) { create(:course, category:, weekday: :tuesday) }
      let(:subscription2) { create(:subscription, member:, courses: [course2], status: :confirmed, year: subscription.year - 1) }

      before do
        subscription2.form.attach(
          io: StringIO.new('dummy pdf content 2'),
          filename: 'form2.pdf',
          content_type: 'application/pdf'
        )
        subscription2.reload
      end

      it 'clears all attached forms' do
        member.update!(first_name: 'NewName')

        expect(subscription.reload.form.attached?).to be false
        expect(subscription2.reload.form.attached?).to be false
      end
    end
  end

  describe 'RELEVANT_ATTRIBUTES constant' do
    it 'contains the expected attributes' do
      expect(described_class::RELEVANT_ATTRIBUTES).to eq(%w[
        first_name
        last_name
        birthdate
        contact_name
        contact_phone_number
        contact_relationship
      ])
    end
  end
end
