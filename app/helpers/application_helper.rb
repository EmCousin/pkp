# frozen_string_literal: true

module ApplicationHelper
  def country_options
    TZInfo::Country.all.sort_by(&:name).map { |country| [country.name, country.code] }
  end

  def number_to_euros(number)
    number_to_currency(number, unit: '€', separator: ',', format: '%n %u')
  end
end
