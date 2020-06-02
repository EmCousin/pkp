# frozen_string_literal: true

module ApplicationHelper
  def number_to_euros(number)
    number_to_currency(number, unit: "€", separator: ",", format: "%n %u")
  end
end
