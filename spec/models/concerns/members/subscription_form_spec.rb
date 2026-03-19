# frozen_string_literal: true

require 'rails_helper'

describe Member, type: :model do
  describe '#clear_subscription_forms' do
    let(:user) { create(:user) }
    let(:member) { create(:member, user: user) }
    let(:subscription) { create(:subscription, member: member, status: :confirmed) }

    before do
      subscription.form.attach(
        io: StringIO.new('dummy pdf content'),
        filename: 'form.pdf',
        content_type: 'application/pdf'
      )
    end

    context 'when member first_name is updated' do
      it 'clears the subscription form' do
        expect { member.update!(first_name: 'NewName') }.to change { subscription.form.attached? }.from(true).to(false)
      end
    end

    context 'when member last_name is updated' do
      it 'clears the subscription form' do
        expect { member.update!(last_name: 'NewLastName') }.to change { subscription.form.attached? }.from(true).to(false)
      end
    end

    context 'when member birthdate is updated' do
      it 'clears the subscription form' do
        expect { member.update!(birthdate: 10.years.ago) }.to change { subscription.form.attached? }.from(true).to(false)
      end
    end

    context 'when member contact_name is updated' do
      it 'clears the subscription form' do
        expect { member.update!(contact_name: 'New Contact') }.to change { subscription.form.attached? }.from(true).to(false)
      end
    end

    context 'when member contact_phone_number is updated' do
      it 'clears the subscription form' do
        expect { member.update!(contact_phone_number: '+33600000000') }.to change { subscription.form.attached? }.from(true).to(false)
      end
    end

    context 'when member contact_relationship is updated' do
      it 'clears the subscription form' do
        expect { member.update!(contact_relationship: 'Autre') }.to change { subscription.form.attached? }.from(true).to(false)
      end
    end

    context 'when member attributes not affecting form are updated' do
      it 'does not clear the subscription form' do
        expect { member.update!(agreed_to_advertising_right: !member.agreed_to_advertising_right) }
          .not_to(change { subscription.form.attached? })
      end
    end

    context 'when member has multiple subscriptions' do
      let(:subscription2) { create(:subscription, member: member, status: :confirmed) }

      before do
        subscription2.form.attach(
          io: StringIO.new('dummy pdf content 2'),
          filename: 'form2.pdf',
          content_type: 'application/pdf'
        )
      end

      it 'clears all subscription forms' do
        member.update!(first_name: 'NewName')
        expect(subscription.form.attached?).to be false
        expect(subscription2.form.attached?).to be false
      end
    end
  end
end
