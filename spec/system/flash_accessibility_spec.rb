# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
describe 'Flash accessibility', type: :system do
  let!(:platform) { create(:platform, domain: 'lvh.me') }
  let!(:user) { create(:user, email: 'parent@example.com', password: 'surprise') }

  before { driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] }
  around { |example| with_app_host('http://lvh.me') { example.run } }

  it 'keeps status messages available and supports native dismissal' do
    allow_any_instance_of(User).to receive(:invalid_email_provider?).and_return(true)
    sign_in_as(user)

    expect(page).to have_css('[role="status"]', count: 2)
    notice, warning = all('#flash-messages details', visible: :visible)
    notice_summary = notice.find('summary', text: 'Fermer')
    warning.hover

    expect(find('#flash-messages')[:'data-controller']).to be_nil
    page.execute_script('arguments[0].focus()', notice_summary)
    expect_component_to_be_accessible('#flash-messages')
    expect(notice_summary[:'aria-describedby']).to eq('flash-notice-message')
    notice_summary.send_keys(:enter)

    expect(page).to have_no_text('Connecté·e.')
    expect(notice_summary).to have_text('Voir')
    expect(page.evaluate_script('document.activeElement === arguments[0]', notice_summary)).to be(true)
    warning_summary = warning.find('summary', text: 'Fermer')
    expect(notice_summary.rect.y + notice_summary.rect.height).to be <= warning_summary.rect.y
    warning_summary.send_keys(:enter)

    expect(page).to have_no_text('bloque les emails automatiques')
  end

  it 'uses an assertive alert for authentication errors' do
    sign_in_as(user, password: 'incorrect')

    alert = find('[role="alert"]')
    flash = alert.find(:xpath, './ancestor::details')
    summary = flash.find('summary', text: 'Fermer')

    expect(flash).to match_css('[open]')
    expect(summary[:'aria-describedby']).to eq('flash-alert-message')
    expect_component_to_be_accessible('#flash-messages')
  end

  it 'hides messages after five seconds when reduced motion is requested' do
    page.driver.browser.execute_cdp(
      'Emulation.setEmulatedMedia',
      features: [{ name: 'prefers-reduced-motion', value: 'reduce' }]
    )

    sign_in_as(user)
    flash = find('#flash-messages details', visible: :visible)

    expect(page.evaluate_script('getComputedStyle(arguments[0]).animationName', flash)).to eq('hide-after-delay')
    expect(page.evaluate_script('getComputedStyle(arguments[0]).animationDuration', flash)).to eq('5s')
    expect(page).to have_no_css('[role="status"]', visible: :visible, wait: 6)
  ensure
    page.driver.browser.execute_cdp('Emulation.setEmulatedMedia', features: [])
  end
end
# rubocop:enable Metrics/BlockLength
