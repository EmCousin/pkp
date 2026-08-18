# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, type: :request) do
    Platform.find_or_create_by!(domain: 'example.com') do |platform|
      platform.name = 'Parkour Paris'
    end
  end

  config.before(:each, type: :feature) do
    Platform.find_or_create_by!(domain: 'example.com') do |platform|
      platform.name = 'Parkour Paris'
    end
  end
end
