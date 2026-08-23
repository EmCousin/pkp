# frozen_string_literal: true

require 'rails_helper'

describe 'PWA service worker', type: :request do
  before { get service_worker_path(format: :js) }

  it 'does not intercept form submissions' do
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("if (event.request.method !== 'GET') return;")
  end

  it 'immediately replaces an outdated worker' do
    expect(response.body).to include('self.skipWaiting()', 'self.clients.claim()')
  end
end
