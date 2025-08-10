require 'rails_helper'

describe Subscriptions::Priceable, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  subject { subscription }

  let(:category_title) { 'Adulte' }
  let(:category) { create :category, title: category_title }
  let(:count) { 1 }
  let(:courses) { create_list :course, count, category: }
  let(:subscription) { build :subscription, courses: courses }
  let(:travel_date) { DateTime.new(Time.now.year, 9).end_of_month }
  let(:pricing) { nil }

  before do
    travel_to travel_date

    pricing if pricing

    courses.each_with_index do |course, index|
      course.weekday = index + 1
    end

    subject.save!
  end

  after do
    travel_back
  end

  it 'sets the category before save' do
    expect(subject.category_id).to eq category.id
  end

  context 'when the category is adulte' do
    let(:category_title) { 'Adulte' }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 240' do
        expect(subject.fee).to eq 240
      end
    end

    context 'when there are 2 courses' do
      let(:count) { 2 }

      it 'should set the fee to 360' do
        expect(subject.fee).to eq 360
      end
    end

    context 'when there are 3 courses' do
      let(:count) { 3 }

      it 'should set the fee to 420' do
        expect(subject.fee).to eq 420
      end
    end
  end

  context 'when the category is Adolescent (10 - 12 ans)' do
    let(:category_title) { 'Adolescent (10 - 12 ans)' }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 240' do
        expect(subject.fee).to eq 240
      end
    end

    context 'when there are 2 courses' do
      let(:count) { 2 }

      it 'should set the fee to 360' do
        expect(subject.fee).to eq 360
      end
    end
  end

  context 'when the category is Adolescent (13 - 15 ans)' do
    let(:category_title) { 'Adolescent (13 - 15 ans)' }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 240' do
        expect(subject.fee).to eq 240
      end
    end

    context 'when there are 2 courses' do
      let(:count) { 2 }

      it 'should set the fee to 360' do
        expect(subject.fee).to eq 360
      end
    end
  end

  context 'when the category is Kidz (6 - 7 ans)' do
    let(:category_title) { 'Kidz (6 - 7 ans)' }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 210' do
        expect(subject.fee).to eq 210
      end
    end
  end

  context 'when the category is Kidz (8 - 9 ans)' do
    let(:category_title) { 'Kidz (8 - 9 ans)' }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 210' do
        expect(subject.fee).to eq 210
      end
    end
  end

  describe 'dynamic pricing with active pricing' do
    let(:travel_date) { DateTime.new(Time.current.year, 9, 15) }

    context 'when category has active pricing' do
      let(:pricing) do
        create(:pricing,
               category:,
               name: 'Test Pricing',
               prices: [280, 420, 490],
               starts_at: Date.new(Time.current.year, 9, 1),
               ends_at: Date.new(Time.current.year + 1, 6, 30))
      end

      context 'when the category is Adulte' do
        let(:category_title) { 'Adulte' }

        context 'when there is 1 course' do
          let(:count) { 1 }

          it 'should use dynamic pricing and set fee to 280' do
            expect(subject.fee).to eq BigDecimal('280')
          end
        end

        context 'when there are 2 courses' do
          let(:count) { 2 }

          it 'should use dynamic pricing and set fee to 420' do
            expect(subject.fee).to eq BigDecimal('420')
          end
        end

        context 'when there are 3 courses' do
          let(:count) { 3 }

          it 'should use dynamic pricing and set fee to 490' do
            expect(subject.fee).to eq BigDecimal('490')
          end
        end

        context 'when there are more courses than prices available' do
          let(:count) { 3 }
          let(:pricing) do
            create(:pricing,
                   category:,
                   name: 'Limited Pricing',
                   prices: [280, 420], # Only has pricing for 2 courses, but 3 courses requested
                   starts_at: Date.new(Time.current.year, 9, 1),
                   ends_at: Date.new(Time.current.year + 1, 6, 30))
          end

          it 'should use the last available price' do
            expect(subject.fee).to eq BigDecimal('420')
          end
        end
      end

      context 'when the category is Adolescent (10 - 12 ans)' do
        let(:category_title) { 'Adolescent (10 - 12 ans)' }
        let(:pricing) do
          create(:pricing,
                 category:,
                 name: 'Teen Pricing',
                 prices: [260, 380],
                 starts_at: Date.new(Time.current.year, 9, 1),
                 ends_at: Date.new(Time.current.year + 1, 6, 30))
        end

        context 'when there is 1 course' do
          let(:count) { 1 }

          it 'should use dynamic pricing and set fee to 260' do
            expect(subject.fee).to eq BigDecimal('260')
          end
        end

        context 'when there are 2 courses' do
          let(:count) { 2 }

          it 'should use dynamic pricing and set fee to 380' do
            expect(subject.fee).to eq BigDecimal('380')
          end
        end
      end

      context 'when the category is Kidz (6 - 7 ans)' do
        let(:category_title) { 'Kidz (6 - 7 ans)' }
        let(:pricing) do
          create(:pricing,
                 category:,
                 name: 'Kidz Pricing',
                 prices: [230],
                 starts_at: Date.new(Time.current.year, 9, 1),
                 ends_at: Date.new(Time.current.year + 1, 6, 30))
        end

        context 'when there is 1 course' do
          let(:count) { 1 }

          it 'should use dynamic pricing and set fee to 230' do
            expect(subject.fee).to eq BigDecimal('230')
          end
        end
      end
    end

    context 'when category has multiple active pricings' do
      let(:category_title) { 'Adulte' }
      let(:count) { 1 }

      let(:travel_date) { DateTime.new(Time.current.year, 10, 15) }

      # Override active_pricing to ensure both pricings are created
      let!(:pricing) do
        # Create both pricings
        older = create(:pricing,
                      category:,
                      name: 'Older Pricing',
                      prices: [280, 420],
                      starts_at: Date.new(Time.current.year, 9, 1),
                      ends_at: Date.new(Time.current.year + 1, 6, 30))

        newer = create(:pricing,
                      category:,
                      name: 'Newer Pricing',
                      prices: [200, 300],
                      starts_at: Date.new(Time.current.year, 10, 1),
                      ends_at: Date.new(Time.current.year + 1, 6, 30))

        [older, newer] # Return both for reference
      end

      it 'should use the most recent active pricing (newer start date)' do
        expect(subject.fee).to eq BigDecimal('200')
      end
    end
  end

  describe 'fallback to legacy pricing' do
    context 'when no active pricing exists for category' do
      # No active_pricing is created, so it should fallback to legacy pricing

      context 'during regular time (September)' do
        let(:travel_date) { DateTime.new(Time.current.year, 9, 15) }

        context 'when the category is Adulte' do
          let(:category_title) { 'Adulte' }

          context 'when there is 1 course' do
            let(:count) { 1 }

            it 'should fallback to legacy pricing and set fee to 240' do
              expect(subject.fee).to eq 240
            end
          end

          context 'when there are 2 courses' do
            let(:count) { 2 }

            it 'should fallback to legacy pricing and set fee to 360' do
              expect(subject.fee).to eq 360
            end
          end

          context 'when there are 3 courses' do
            let(:count) { 3 }

            it 'should fallback to legacy pricing and set fee to 420' do
              expect(subject.fee).to eq 420
            end
          end
        end

        context 'when the category is Kidz (6 - 7 ans)' do
          let(:category_title) { 'Kidz (6 - 7 ans)' }

          context 'when there is 1 course' do
            let(:count) { 1 }

            it 'should fallback to legacy pricing and set fee to 210' do
              expect(subject.fee).to eq 210
            end
          end
        end
      end

      context 'during spring time' do
        let(:travel_date) { DateTime.new(Time.current.year, 4, 15) }

        context 'when the category is Adulte' do
          let(:category_title) { 'Adulte' }

          context 'when there is 1 course' do
            let(:count) { 1 }

            it 'should fallback to legacy spring pricing and set fee to 145' do
              expect(subject.fee).to eq 145
            end
          end

          context 'when there are 2 courses' do
            let(:count) { 2 }

            it 'should fallback to legacy spring pricing and set fee to 215' do
              expect(subject.fee).to eq 215
            end
          end
        end

        context 'when the category is Kidz (6 - 7 ans)' do
          let(:category_title) { 'Kidz (6 - 7 ans)' }

          context 'when there is 1 course' do
            let(:count) { 1 }

            it 'should fallback to legacy spring pricing and set fee to 120' do
              expect(subject.fee).to eq 120
            end
          end
        end
      end

      context 'during winter time' do
        let(:travel_date) { DateTime.new(Time.current.year, 1, 15) }

        context 'when the category is Adulte' do
          let(:category_title) { 'Adulte' }

          context 'when there is 1 course' do
            let(:count) { 1 }

            it 'should fallback to legacy winter pricing and set fee to 205' do
              expect(subject.fee).to eq 205
            end
          end

          context 'when there are 2 courses' do
            let(:count) { 2 }

            it 'should fallback to legacy winter pricing and set fee to 275' do
              expect(subject.fee).to eq 275
            end
          end
        end

        context 'when the category is Kidz (6 - 7 ans)' do
          let(:category_title) { 'Kidz (6 - 7 ans)' }

          context 'when there is 1 course' do
            let(:count) { 1 }

            it 'should fallback to legacy winter pricing and set fee to 155' do
              expect(subject.fee).to eq 155
            end
          end
        end
      end
    end

    context 'when active pricing exists but covers different date range' do
      let(:travel_date) { DateTime.new(Time.current.year, 9, 15) }
      let(:category_title) { 'Adulte' }
      let(:count) { 1 }

      let(:pricing) do
        create(:pricing,
               category:,
               name: 'Future Pricing',
               prices: [300, 450],
               starts_at: Date.new(Time.current.year + 1, 1, 1),
               ends_at: Date.new(Time.current.year + 1, 12, 31))
      end

      it 'should fallback to legacy pricing when active pricing does not cover current date' do
        expect(subject.fee).to eq 240
      end
    end

    context 'when active pricing exists but has no prices for course count' do
      let(:travel_date) { DateTime.new(Time.current.year, 9, 15) }
      let(:category_title) { 'Adulte' }
      let(:count) { 3 }

      let(:pricing) do
        create(:pricing,
               category:,
               name: 'Limited Pricing',
               prices: [280], # Only has pricing for 1 course, but 3 courses requested
               starts_at: Date.new(Time.current.year, 9, 1),
               ends_at: Date.new(Time.current.year + 1, 6, 30))
      end

      it 'should fallback to legacy pricing when dynamic pricing has no price for course count' do
        expect(subject.fee).to eq 420 # Falls back to legacy pricing for 3 courses
      end
    end
  end

  describe '.winter_time?' do
    let(:current_time) { DateTime.new(Subscription.current_year, 9).end_of_month }

    it { travel_to(current_time) { expect(Subscription.winter_time?).to be false } }

    context 'when it is between December 20 and July 1st' do
      let(:current_time) { DateTime.new(Subscription.current_year, 12, 30).end_of_day }

      it { travel_to(current_time) { expect(Subscription.winter_time?).to be true } }
    end
  end

  describe '#fee_cents' do
    let(:category_title) { 'Kidz (8 - 9 ans)' }
    let(:count) { 1 }

    it { expect(subject.fee_cents).to eq 21000 }
  end

  describe 'spring pricing' do
    let(:travel_date) { DateTime.new(Time.now.year, 4).end_of_month }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 120' do
        expect(subject.fee).to eq 145
      end
    end

    context 'when there are 2 courses' do
      let(:count) { 2 }

      it 'should set the fee to 215' do
        expect(subject.fee).to eq 215
      end
    end

    context 'when the category is Adolescent (10 - 12 ans)' do
      let(:category_title) { 'Adolescent (10 - 12 ans)' }

      context 'when there is 1 course' do
        let(:count) { 1 }

        it 'should set the fee to 145' do
          expect(subject.fee).to eq 145
        end
      end

      context 'when there are 2 courses' do
        let(:count) { 2 }

        it 'should set the fee to 215' do
          expect(subject.fee).to eq 215
        end
      end
    end

    context 'when the category is Adolescent (13 - 15 ans)' do
      let(:category_title) { 'Adolescent (13 - 15 ans)' }

      context 'when there is 1 course' do
        let(:count) { 1 }

        it 'should set the fee to 145' do
          expect(subject.fee).to eq 145
        end
      end

      context 'when there are 2 courses' do
        let(:count) { 2 }

        it 'should set the fee to 215' do
          expect(subject.fee).to eq 215
        end
      end
    end

    context 'when the category is Kidz (6 - 7 ans)' do
      let(:category_title) { 'Kidz (6 - 7 ans)' }

      context 'when there is 1 course' do
        let(:count) { 1 }

        it 'should set the fee to 120' do
          expect(subject.fee).to eq 120
        end
      end
    end

    context 'when the category is Kidz (8 - 9 ans)' do
      let(:category_title) { 'Kidz (8 - 9 ans)' }

      context 'when there is 1 course' do
        let(:count) { 1 }

        it 'should set the fee to 120' do
          expect(subject.fee).to eq 120
        end
      end
    end
  end

  describe 'winter pricing' do
    let(:travel_date) { DateTime.new(Time.now.year, 1).end_of_month }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 205' do
        expect(subject.fee).to eq 205
      end
    end

    context 'when there are 2 courses' do
      let(:count) { 2 }

      it 'should set the fee to 275' do
        expect(subject.fee).to eq 275
      end
    end

    context 'when the category is Adolescent (10 - 12 ans)' do
      let(:category_title) { 'Adolescent (10 - 12 ans)' }

      context 'when there is 1 course' do
        let(:count) { 1 }

        it 'should set the fee to 205' do
          expect(subject.fee).to eq 205
        end
      end

      context 'when there are 2 courses' do
        let(:count) { 2 }

        it 'should set the fee to 275' do
          expect(subject.fee).to eq 275
        end
      end
    end

    context 'when the category is Adolescent (13 - 15 ans)' do
      let(:category_title) { 'Adolescent (13 - 15 ans)' }

      context 'when there is 1 course' do
        let(:count) { 1 }

        it 'should set the fee to 205' do
          expect(subject.fee).to eq 205
        end
      end

      context 'when there are 2 courses' do
        let(:count) { 2 }

        it 'should set the fee to 275' do
          expect(subject.fee).to eq 275
        end
      end
    end

    context 'when the category is Kidz (6 - 7 ans)' do
      let(:category_title) { 'Kidz (6 - 7 ans)' }

      context 'when there is 1 course' do
        let(:count) { 1 }

        it 'should set the fee to 155' do
          expect(subject.fee).to eq 155
        end
      end
    end

    context 'when the category is Kidz (8 - 9 ans)' do
      let(:category_title) { 'Kidz (8 - 9 ans)' }

      context 'when there is 1 course' do
        let(:count) { 1 }

        it 'should set the fee to 155' do
          expect(subject.fee).to eq 155
        end
      end
    end
  end
end
