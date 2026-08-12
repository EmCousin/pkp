# frozen_string_literal: true

module ApplicationHelper
  def countries_by_name
    TZInfo::Country.all.sort_by(&:name)
  end

  def number_to_euros(number)
    number_to_currency(number, unit: '€', separator: ',', format: '%n %u')
  end
end
