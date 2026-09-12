# frozen_string_literal: true

require 'rails_helper'

describe 'Accessibility foundations', type: :system do
  let!(:platform) { create(:platform, domain: 'lvh.me') }

  before { driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] }
  around { |example| with_app_host('http://lvh.me') { example.run } }

  it 'does not overflow at a 320-pixel viewport' do
    with_mobile_viewport do
      visit new_user_session_path

      viewport_width = page.evaluate_script('document.documentElement.clientWidth')
      content_width = page.evaluate_script('document.documentElement.scrollWidth')

      expect(content_width).to be <= viewport_width
    end
  end
end
