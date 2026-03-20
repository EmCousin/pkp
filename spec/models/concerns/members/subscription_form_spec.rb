# frozen_string_literal: true

require 'rails_helper'

describe Member, type: :model do
  describe '#clear_subscription_forms' do
    let(:user) { create(:user) }
    let(:member) { create(:member, user: user) }
    let(:category) { create(:category) }
    let(:course) { create(:course, category: category) }
    let(:subscription) { create(:subscription, member: member, status: :confirmed, courses: [course]) }

    before do
      subscription.form.attach(
        io: StringIO.new('dummy pdf content'),
        filename: 'form.pdf',
        content_type: 'application/pdf'
      )
      subscription.reload
    end

    context 'when member first_name is updated' do
      it 'clears the subscription form' do
        member.update!(first_name: 'NewName')
        expect(subscription.reload.form.attached?).to be false
      end
    end

    context 'when member last_name is updated' do
      it 'clears the subscription form' do
        member.update!(last_name: 'NewLastName')
        expect(subscription.reload.form.attached?).to be false
      end
    end

    context 'when member birthdate is updated' do
      it 'clears the subscription form' do
        member.update!(birthdate: 10.years.ago)
        expect(subscription.reload.form.attached?).to be false
      end
    end

    context 'when member contact_name is updated' do
      it 'clears the subscription form' do
        member.update!(contact_name: 'New Contact')
        expect(subscription.reload.form.attached?).to be false
      end
    end

    context 'when member contact_phone_number is updated' do
      it 'clears the subscription form' do
        member.update!(contact_phone_number: '+33600000000')
        expect(subscription.reload.form.attached?).to be false
      end
    end

    context 'when member contact_relationship is updated' do
      it 'clears the subscription form' do
        member.update!(contact_relationship: 'Autre')
        expect(subscription.reload.form.attached?).to be false
      end
    end

    context 'when member attributes not affecting form are updated' do
      it 'does not clear the subscription form' do
        member.update!(agreed_to_advertising_right: !member.agreed_to_advertising_right)
        expect(subscription.reload.form.attached?).to be true
      end
    end

    context 'when member has multiple subscriptions' do
      let(:course2) { create(:course, category: category, weekday: Course.weekdays.keys.last) }
      let(:subscription2) { create(:subscription, member: member, status: :confirmed, courses: [course2]) }

      before do
        subscription2.form.attach(
          io: StringIO.new('dummy pdf content 2'),
          filename: 'form2.pdf',
          content_type: 'application/pdf'
        )
        subscription2.reload
      end

      it 'clears all subscription forms' do
        member.update!(first_name: 'NewName')
        expect(subscription.reload.form.attached?).to be false
        expect(subscription2.reload.form.attached?).to be false
      end
    end
  end
end
