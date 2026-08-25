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

  it 'toggles details with a named button and hides collapsed content' do
    sign_in_as(user)
    card_id = ActionView::RecordIdentifier.dom_id(subscription, :card)
    details_id = ActionView::RecordIdentifier.dom_id(subscription, :details)
    card = find("##{card_id}")
    button = card.find("button[aria-controls='#{details_id}']")
    details = card.find("##{details_id}", visible: :all)

    expect(button[:'aria-expanded']).to eq('false')
    expect(details).not_to be_visible

    page.execute_script('arguments[0].focus()', button)
    expect(page.evaluate_script('getComputedStyle(arguments[0]).boxShadow', button)).not_to eq('none')
    button.send_keys(:enter)

    expect(button[:'aria-expanded']).to eq('true')
    expect(button).to have_text('Masquer les détails')
    expect(details).to be_visible
    expect(page.evaluate_script('document.activeElement === arguments[0]', button)).to be(true)
    expect_component_to_be_accessible("##{card_id}")

    button.send_keys(:space)
    expect(button[:'aria-expanded']).to eq('false')
    expect(details).not_to be_visible
  end

  it 'starts expanded when there is only one subscription' do
    other_subscription.destroy!
    sign_in_as(user)
    card_id = ActionView::RecordIdentifier.dom_id(subscription, :card)
    details_id = ActionView::RecordIdentifier.dom_id(subscription, :details)
    card = find("##{card_id}")
    button = card.find("button[aria-controls='#{details_id}']")

    expect(button[:'aria-expanded']).to eq('true')
    expect(button).to have_text('Masquer les détails')
    expect(card.find("##{details_id}")).to be_visible
  end
end
# rubocop:enable Metrics/BlockLength
