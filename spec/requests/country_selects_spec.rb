# frozen_string_literal: true

require 'rails_helper'

describe 'Country selects', type: :request do
  include Devise::Test::IntegrationHelpers

  it 'uses country names as labels and ISO codes as values on the account form' do
    sign_in create(:user)

    get edit_user_registration_path

    options = country_options(response.body, '#user_country')
    expect(options).to include('France' => 'FR', 'Germany' => 'DE')
  end

  it 'uses country names as labels and ISO codes as values on the admin member form' do
    sign_in create(:user, :admin)

    get new_admin_member_path

    options = country_options(response.body, 'select[name="member[user_attributes][country]"]')
    expect(options).to include('France' => 'FR', 'Germany' => 'DE')
  end

  def country_options(body, selector)
    Nokogiri::HTML(body).css("#{selector} option").to_h { |option| [option.text, option['value']] }
  end
end
