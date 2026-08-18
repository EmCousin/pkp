# frozen_string_literal: true

require 'rails_helper'

describe Current do
  after { described_class.reset }

  it 'sets the domain from the current request' do
    request = instance_double(ActionDispatch::Request, domain: 'localhost')

    described_class.request = request

    expect(described_class.request).to eq(request)
    expect(described_class.domain).to eq('localhost')
  end

  it 'uses an empty domain when the request host has no registrable domain' do
    described_class.request = instance_double(ActionDispatch::Request, domain: nil)

    expect(described_class.domain).to eq('')
  end
end
