# frozen_string_literal: true

require 'rails_helper'

describe 'Mobile navigation accessibility', type: :system do
  let!(:platform) { create(:platform, domain: 'lvh.me') }

  before { driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] }
  around { |example| with_app_host('http://lvh.me') { example.run } }

  it 'keeps closed links out of the tab order and exposes keyboard controls' do
    with_mobile_viewport do
      visit new_user_session_path
      details = find('nav details')
      summary = details.find('summary', text: 'Menu principal')

      expect(details).to have_no_link('Connexion', visible: :visible)
      page.execute_script('arguments[0].focus()', summary)
      expect(page.evaluate_script('getComputedStyle(arguments[0]).boxShadow', summary)).not_to eq('none')
      summary.send_keys(:enter)

      expect(details).to match_css('[open]')
      expect(details).to have_link('Connexion', visible: :visible)
      expect_component_to_be_accessible('nav')

      press_tab
      expect(page.evaluate_script('document.activeElement.textContent.trim()')).to eq('Connexion')

      page.execute_script('arguments[0].focus()', summary)
      summary.send_keys(:space)
      press_tab

      expect(page.evaluate_script('document.activeElement.id')).to eq('user_email')
    end
  end
end
