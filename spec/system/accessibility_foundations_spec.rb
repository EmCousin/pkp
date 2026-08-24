# frozen_string_literal: true

require 'rails_helper'

describe 'Accessibility foundations', type: :system do
  let!(:platform) { create(:platform, domain: 'lvh.me') }

  before { driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] }
  around { |example| with_app_host('http://lvh.me') { example.run } }

  it 'provides document landmarks and keyboard bypass navigation' do
    visit new_user_session_path

    expect(page.title).to eq('Connexion | Parkour Paris')
    expect(page).to have_css('html[lang="fr"]')
    expect(page).to have_css('main#main-content[tabindex="-1"]')
    expect_accessible_foundations

    press_tab

    expect(page).to have_css('a[href="#main-content"]:focus', text: 'Aller au contenu principal')
    skip_link = find('a[href="#main-content"]')
    expect(skip_link.rect.width).to be > 1
    expect(skip_link.rect.height).to be > 1

    press_enter

    expect(page.evaluate_script('document.activeElement.id')).to eq('main-content')
  end

  it 'does not overflow at a 320-pixel viewport' do
    with_mobile_viewport do
      visit new_user_session_path

      viewport_width = page.evaluate_script('document.documentElement.clientWidth')
      content_width = page.evaluate_script('document.documentElement.scrollWidth')

      expect(content_width).to be <= viewport_width
    end
  end
end
