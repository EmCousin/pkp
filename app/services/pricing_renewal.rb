# frozen_string_literal: true

class PricingRenewal
  def initialize(year:, categories: Current.platform.categories)
    @year = year
    @categories = categories
  end

  def call
    categories.find_each.count { |category| renew(category) }
  end

  private

  attr_reader :year, :categories

  def renew(category)
    category.with_lock do
      return false if category.pricings.covering_year(year).exists?

      previous_pricings = category.pricings.covering_year(year - 1).to_a
      return false if previous_pricings.empty?

      previous_pricings.each { |pricing| copy(pricing, category) }
      true
    end
  end

  def copy(pricing, category)
    category.pricings.create!(
      name: pricing.name,
      prices: pricing.prices,
      starts_at: pricing.starts_at.next_year,
      ends_at: pricing.ends_at.next_year
    )
  end
end
