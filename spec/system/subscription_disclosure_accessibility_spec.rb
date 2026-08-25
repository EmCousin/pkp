# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
describe 'Subscription disclosure accessibility', type: :system do
  let!(:platform) { create(:platform, domain: 'lvh.me') }
  let!(:user) { create(:user, email: 'parent@example.com', password: 'surprise') }
  let!(:category) { create(:category, platform:) }
  let!(:pricing) { create(:pricing, category:) }
  let!(:course) { create(:course, category:, title: 'Cours du lundi') }
  let!(:member) { create(:member, user:, platform:, first_name: 'Jane', last_name: 'Doe') }
  let!(:subscription) { create(:subscription, member:, courses: [course]) }
  let!(:other_subscription) do
    other_member = create(:member, user:, platform:, first_name: 'John', last_name: 'Doe')
    create(:subscription, member: other_member, courses: [course])
  end

  before { driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] }

  around { |example| with_app_host('http://lvh.me') { example.run } }

  it 'toggles details with a named native control and hides collapsed content' do
    sign_in_as(user)
    card_id = ActionView::RecordIdentifier.dom_id(subscription, :card)
    details_id = ActionView::RecordIdentifier.dom_id(subscription, :details)
    card = find("##{card_id}")
    summary = card.find("summary[aria-controls='#{details_id}']", text: 'Voir les détails')
    disclosure = summary.find(:xpath, '..')
    content = card.find("##{details_id}", visible: :all)

    expect(card[:'data-controller']).to be_nil
    expect(disclosure).not_to match_css('[open]')
    expect(summary[:'aria-controls']).to eq(details_id)
    expect(content).not_to be_visible

    page.execute_script('arguments[0].focus()', summary)
    expect(page.evaluate_script('getComputedStyle(arguments[0]).boxShadow', summary)).not_to eq('none')
    summary.send_keys(:enter)

    expect(disclosure).to match_css('[open]')
    expect(summary).to have_text('Masquer les détails')
    expect(content).to be_visible
    expect(page.evaluate_script('document.activeElement === arguments[0]', summary)).to be(true)
    expect_component_to_be_accessible("##{card_id}")

    summary.send_keys(:space)
    expect(disclosure).not_to match_css('[open]')
    expect(content).not_to be_visible
  end

  it 'starts expanded when there is only one subscription' do
    other_subscription.destroy!
    sign_in_as(user)
    card_id = ActionView::RecordIdentifier.dom_id(subscription, :card)
    details_id = ActionView::RecordIdentifier.dom_id(subscription, :details)
    card = find("##{card_id}")
    summary = card.find("summary[aria-controls='#{details_id}']")
    disclosure = summary.find(:xpath, '..')

    expect(disclosure).to match_css('[open]')
    expect(summary).to have_text('Masquer les détails')
    expect(card.find("##{details_id}")).to be_visible
  end
end
# rubocop:enable Metrics/BlockLength
