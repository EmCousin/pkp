# frozen_string_literal: true

module SubscriptionsHelper
  def subscriptions_year_select_options(year)
    options = (2019..Subscription.current_year).reverse_each.map { |year| ["#{year} - #{year + 1}", year] }
    options_for_select(options, year)
  end

  def subscriptions_status_select_options(status)
    options = Subscription.statuses.map { |key, _value| [key, I18n.t("activerecord.attributes.subscription.statuses")[key.to_sym]] }
    options_for_select(options, status)
  end

  def subscriptions_level_select_options(level)
    options_for_select(subscriptions_level_options, level)
  end

  def subscriptions_level_options
    Member.levels.map { |key, _value| [key, I18n.t("activerecord.attributes.member.levels")[key.to_sym]] }
  end
end
