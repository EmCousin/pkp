# frozen_string_literal: true

require 'axe-rspec'

module AccessibilityHelpers
  WCAG_TAGS = %i[wcag2a wcag2aa wcag21a wcag21aa wcag22aa].freeze
  FOUNDATION_RULES = %w[document-title html-has-lang landmark-one-main].freeze

  def expect_page_to_be_accessible
    expect(page).to be_axe_clean.according_to(*WCAG_TAGS)
  end

  def expect_accessible_foundations
    expect(page).to be_axe_clean.checking_only(*FOUNDATION_RULES)
  end

  def with_mobile_viewport
    original_size = page.current_window.size
    page.current_window.resize_to(320, 800)

    yield
  ensure
    page.current_window.resize_to(*original_size) if original_size
  end

  def press_tab
    page.send_keys(:tab)
  end

  def press_enter
    page.send_keys(:enter)
  end

  def with_app_host(host)
    previous_app_host = Capybara.app_host
    previous_always_include_port = Capybara.always_include_port
    Capybara.app_host = host
    Capybara.always_include_port = true

    yield
  ensure
    Capybara.app_host = previous_app_host
    Capybara.always_include_port = previous_always_include_port
  end
end

RSpec.configure do |config|
  config.include AccessibilityHelpers, type: :system
end
