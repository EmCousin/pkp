require 'rails_helper'

describe Members::Available, type: :model do
  describe '.available' do
    let(:year) { Subscription.current_year }

    it 'takes the Subscription current year as a default param' do
      expect(Member.available).to eq Member.available(Subscription.current_year)
    end

    it 'performs a SQL query' do
      expect(Member.available(year).to_sql).to eq(
        Member.left_joins(:subscriptions)
              .where(subscriptions: { id: nil })
              .or(
                Member.left_joins(:subscriptions)
                      .where.not(subscriptions: { year: year })
              ).to_sql
      )
    end

    context 'when the member has no subscriptions' do
      let!(:member) { create :member }

      it { expect(Member.available(year)).to include member }
    end

    context 'when the member has a subscription' do
      let(:courses) { create_list(:course, 1) }
      let(:member) { create :member }
      let!(:subscription) { create :subscription, member: member, courses: courses, year: year }

      it { expect(Member.available(year)).not_to include member }

      context 'when the member has a subscription from another year' do
        before { subscription.decrement!(:year) }

        it { expect(Member.available(year)).to include member }
      end
    end

    context 'when the year is in the future' do
      let(:year) { Subscription.current_year + 1 }

      it { expect(Member.available(year)).to eq Member.none }
    end
  end
end
