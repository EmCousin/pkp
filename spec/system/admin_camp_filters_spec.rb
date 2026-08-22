# frozen_string_literal: true

require 'rails_helper'

describe 'Admin camp filters', type: :system do
  let!(:platform) { create(:platform, domain: 'lvh.me') }
  let!(:admin) { create(:user, :admin, email: 'admin@example.com', password: 'surprise') }

  before { driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] }

  around do |example|
    previous_app_host = Capybara.app_host
    previous_always_include_port = Capybara.always_include_port
    Capybara.app_host = 'http://lvh.me'
    Capybara.always_include_port = true

    example.run
  ensure
    Capybara.app_host = previous_app_host
    Capybara.always_include_port = previous_always_include_port
  end

  it 'toggles each switch by clicking its label' do
    visit new_user_session_path
    fill_in 'user_email', with: admin.email
    fill_in 'user_password', with: 'surprise'
    click_button 'Connexion'

    visit admin_camps_path

    %i[active visible_to_externals open open_to_externals].each do |filter|
      find('label', text: Camp.human_attribute_name(filter)).click
      expect(find_field(filter, visible: :all)).to be_checked
    end
  end
end
