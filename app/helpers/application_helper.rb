# frozen_string_literal: true

module ApplicationHelper
  def number_to_euros(number)
    number_to_currency(number, unit: '€', separator: ',', format: '%n %u')
  end

  def discovery_session_date(discovery_session)
    value = discovery_session.occurs_on || discovery_session.starts_at
    l(value, format: discovery_session.occurs_on? ? :long : :event)
  end
end
