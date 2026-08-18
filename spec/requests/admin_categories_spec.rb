# frozen_string_literal: true

require 'rails_helper'

describe 'Admin categories', type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveSupport::Testing::TimeHelpers

  let(:pricing_year) { Date.current.year + 1 }

  before do
    travel_to Date.new(2026, 8, 12)
    sign_in create(:user, :admin, phone_number: '+33612345679')
  end

  it 'warns on every admin page when next season pricing is missing' do
    create(:category)

    get admin_members_path

    expect(response.body).to include('La saison 2026-2027 approche')
    expect(response.body).to include(admin_categories_path)
  end

  it 'does not expose categories from another platform' do
    current_category = create(:category, title: 'Parkour Paris')
    other_platform = create(:platform, name: 'Other platform')
    other_category = create(:category, platform: other_platform, title: 'Other category')

    get admin_categories_path

    expect(response.body).to include(current_category.title)
    expect(response.body).not_to include(other_category.title)

    get admin_category_path(other_category)

    expect(response).to have_http_status(:not_found)
  end

  it 'renews previous season prices without replacing existing prices' do
    renewed_category = create(:category, title: 'Adultes')
    previous_pricing = create(
      :pricing,
      category: renewed_category,
      name: 'Tarif annuel',
      prices: [280, 420],
      starts_at: Date.new(2025, 8, 1),
      ends_at: Date.new(2026, 6, 30)
    )
    configured_category = create(:category, title: 'Ados')
    existing_pricing = create(
      :pricing,
      category: configured_category,
      name: 'Tarif personnalisé',
      prices: [300],
      starts_at: Date.new(2026, 8, 1),
      ends_at: Date.new(2027, 6, 30)
    )
    other_platform = create(:platform, name: 'Other platform')
    other_category = create(:category, platform: other_platform, title: 'Other adults')
    create(
      :pricing,
      category: other_category,
      starts_at: Date.new(2025, 8, 1),
      ends_at: Date.new(2026, 6, 30)
    )

    expect do
      post renew_pricings_admin_categories_path
    end.to change(Pricing, :count).by(1)

    renewed_pricing = renewed_category.pricings.covering_year(pricing_year).sole
    expect(renewed_pricing).to have_attributes(
      name: previous_pricing.name,
      prices: previous_pricing.prices,
      starts_at: previous_pricing.starts_at.next_year,
      ends_at: previous_pricing.ends_at.next_year
    )
    expect(configured_category.pricings.covering_year(pricing_year)).to contain_exactly(existing_pricing)
    expect(other_category.pricings.covering_year(pricing_year)).to be_empty
    expect(response).to redirect_to(admin_categories_path)

    get admin_category_path(renewed_category)
    selected_year = Nokogiri::HTML(response.body).at_css('select[name="year"] option[selected]')
    expect(selected_year['value']).to eq(pricing_year.to_s)
    expect(response.body).to include(I18n.l(renewed_pricing.starts_at, format: :short))

    expect do
      post renew_pricings_admin_categories_path
    end.not_to change(Pricing, :count)
  end

  it 'warns when there are no previous season prices to renew' do
    create(:category)

    expect do
      post renew_pricings_admin_categories_path
    end.not_to change(Pricing, :count)

    expect(flash[:alert]).to eq("Aucun tarif n'a été reconduit. Vérifiez que les catégories ont des tarifs pour la saison précédente.")
  end
end
