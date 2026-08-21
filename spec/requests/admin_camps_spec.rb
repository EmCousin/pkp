# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
describe 'Admin camps', type: :request do
  include Devise::Test::IntegrationHelpers

  before { sign_in create(:user, :admin, phone_number: '+33612345679') }

  it 'searches and filters camps' do
    year = Subscription.current_year
    starts_at = Course.vacation_start(year).to_date + 1.month
    attributes = {
      starts_at:,
      ends_at: starts_at + 2.days,
      active: false,
      open: true,
      open_to_externals: false
    }
    matching = create(:camp, **attributes, title: 'Stage cible')
    other_name = create(:camp, **attributes, title: 'Stage différent')
    visible = create(:camp, **attributes, title: 'Stage cible visible', active: true)
    closed_to_students = create(:camp, **attributes, title: 'Stage cible fermé aux élèves', open: false)
    open_to_externals = create(:camp, **attributes, title: 'Stage cible externes', open_to_externals: true)
    other_year_start = Course.vacation_start(year - 1).to_date + 1.month
    other_year = create(:camp, **attributes, title: 'Stage cible autre année',
                                             starts_at: other_year_start, ends_at: other_year_start + 2.days)

    get admin_camps_path(q: 'CIBLE', active: 'false', open: 'true', open_to_externals: 'false', year:)

    expect(response.body).to include(admin_camp_path(matching))
    expect(response.body).not_to include(
      admin_camp_path(other_name),
      admin_camp_path(visible),
      admin_camp_path(closed_to_students),
      admin_camp_path(open_to_externals),
      admin_camp_path(other_year)
    )
    expect(response.body).to include('name="q"', 'name="active"', 'name="open"', 'name="open_to_externals"', 'name="year"')
  end

  it 'paginates camps and preserves the search' do
    create_list(:camp, 26, title: 'Stage Pagination')

    get admin_camps_path(q: 'Pagination')

    expect(response.body).to include('page=2', 'q=Pagination')
  end
end
# rubocop:enable Metrics/BlockLength
