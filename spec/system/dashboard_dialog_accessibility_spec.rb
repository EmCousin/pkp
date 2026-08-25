# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
describe 'Dashboard dialog accessibility', type: :system do
  let!(:platform) { create(:platform, domain: 'lvh.me') }
  let!(:user) { create(:user, email: 'parent@example.com', password: 'surprise') }
  let!(:category) { create(:category, platform:) }
  let!(:pricing) { create(:pricing, category:) }
  let!(:course) { create(:course, category:) }
  let!(:member) { create(:member, user:, platform:) }
  let!(:subscription) { create(:subscription, member:, courses: [course]) }

  before { driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] }
  around { |example| with_app_host('http://lvh.me') { example.run } }

  it 'names the modal and restores focus for each keyboard close action' do
    sign_in_as(user)
    trigger = find('#subscription-instructions-trigger')
    trigger.send_keys(:enter)
    dialog = find('#subscription-instructions-dialog[open]')

    expect(dialog[:'aria-labelledby']).to eq('subscription-instructions-title')
    expect(page.evaluate_script('document.activeElement.id')).to eq('subscription-instructions-title')
    expect(dialog).to have_css('button[aria-label="Fermer"]')
    expect(dialog).to have_button('Fermer')
    expect_component_to_be_accessible('#subscription-instructions-dialog')

    page.send_keys(:escape)
    expect(page).to have_no_css('#subscription-instructions-dialog[open]')
    expect(page.evaluate_script('document.activeElement === arguments[0]', trigger)).to be(true)

    trigger.send_keys(:space)
    footer_close = find('#subscription-instructions-dialog[open] button', text: 'Fermer')
    footer_close.send_keys(:enter)

    expect(page).to have_no_css('#subscription-instructions-dialog[open]')
    expect(page.evaluate_script('document.activeElement === arguments[0]', trigger)).to be(true)

    trigger.send_keys(:enter)
    icon_close = find('#subscription-instructions-dialog[open] button[aria-label="Fermer"]')
    icon_close.send_keys(:enter)

    expect(page).to have_no_css('#subscription-instructions-dialog[open]')
    expect(page.evaluate_script('document.activeElement === arguments[0]', trigger)).to be(true)
  end
end
# rubocop:enable Metrics/BlockLength
