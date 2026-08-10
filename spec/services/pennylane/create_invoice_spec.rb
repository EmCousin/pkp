require 'rails_helper'

describe Pennylane::CreateInvoice, type: :service do
  subject(:create_invoice) { described_class.new(subscription, client:) }

  let(:client) { instance_double(Pennylane::Client) }
  let(:user) { create(:user) }
  let(:member) { create(:member, user:) }
  let(:discovery_session) { create(:discovery_session, starts_at: Time.zone.local(2026, 9, 12, 14), price: 36) }
  let(:subscription) do
    create(:discovery_registration, member:, discovery_session:, paid_at: Time.current, payment_method: :credit_card)
  end
  let(:customer) { { 'id' => 123 } }
  let(:created_invoice) { { 'id' => 456, 'invoice_number' => 'F20260001' } }
  let(:unpaid_invoice) { created_invoice.merge('paid' => false, 'public_file_url' => nil) }
  let(:paid_invoice) do
    created_invoice.merge('paid' => true, 'public_file_url' => 'https://files.example.test/invoice.pdf')
  end

  before do
    allow(client).to receive(:find_customer).with("pkp-user-#{user.id}").and_return(customer)
    allow(client).to receive(:update_customer).with(123, anything)
    allow(client).to receive(:find_invoice).with("pkp-subscription-#{subscription.id}").and_return(nil)
    allow(client).to receive(:create_invoice).and_return(created_invoice)
    allow(client).to receive(:invoice).with(456).and_return(unpaid_invoice, paid_invoice)
    allow(client).to receive(:mark_invoice_as_paid).with(456)
    allow(client).to receive(:download).with('https://files.example.test/invoice.pdf').and_return('%PDF invoice')
  end

  it 'creates a finalized paid invoice from the tax-inclusive registration fee' do
    create_invoice.call

    expect(client).to have_received(:create_invoice).with(hash_including(
      customer_id: 123,
      draft: false,
      external_reference: "pkp-subscription-#{subscription.id}",
      pdf_invoice_subject: "Cours découverte - #{discovery_session.course.title}",
      invoice_lines: [hash_including(
        label: "Cours découverte - #{discovery_session.course.title}",
        raw_currency_unit_price: '30.0',
        vat_rate: 'FR_200',
        quantity: 1
      )]
    ))
    expect(client).to have_received(:mark_invoice_as_paid).with(456)
    expect(subscription.reload).to have_attributes(
      pennylane_invoice_id: 456,
      pennylane_invoice_number: 'F20260001',
      pennylane_invoice_error: nil
    )
    expect(subscription.invoice).to be_attached
  end

  it 'creates the Pennylane customer from the account holder' do
    allow(client).to receive(:find_customer).and_return(nil)
    allow(client).to receive(:create_customer).and_return(customer)

    create_invoice.call

    expect(client).to have_received(:create_customer).with(
      first_name: user.first_name,
      last_name: user.last_name,
      phone: user.phone_number,
      emails: [user.email],
      external_reference: "pkp-user-#{user.id}",
      billing_language: 'fr_FR',
      payment_conditions: 'upon_receipt',
      billing_address: {
        address: user.address,
        postal_code: user.zip_code,
        city: user.city,
        country_alpha2: 'FR'
      }
    )
    expect(user.reload.pennylane_customer_id).to eq(123)
  end

  it 'refreshes an existing Pennylane customer before invoicing' do
    user.update_column(:pennylane_customer_id, 123)

    create_invoice.call

    expect(client).not_to have_received(:find_customer)
    expect(client).to have_received(:update_customer).with(123, hash_including(
      first_name: user.first_name,
      last_name: user.last_name,
      emails: [user.email]
    ))
  end

  it 'resumes an existing invoice instead of creating a duplicate' do
    subscription.update_column(:pennylane_invoice_id, 456)

    create_invoice.call

    expect(client).not_to have_received(:find_invoice)
    expect(client).not_to have_received(:create_invoice)
    expect(subscription.invoice).to be_attached
  end

  it 'recovers the existing invoice after a concurrent creation conflict' do
    allow(client).to receive(:find_invoice)
      .with("pkp-subscription-#{subscription.id}")
      .and_return(nil, created_invoice)
    allow(client).to receive(:create_invoice)
      .and_raise(Pennylane::Error.new('Already exists', status: 409))

    create_invoice.call

    expect(client).to have_received(:find_invoice).twice
    expect(subscription.reload.pennylane_invoice_id).to eq(456)
  end

  context 'with an annual registration' do
    let(:subscription) do
      create(:subscription, member:, courses: [create(:course)], paid_at: Time.current, payment_method: :bank_transfer)
    end

    it 'identifies the annual season and courses' do
      create_invoice.call

      expect(client).to have_received(:create_invoice).with(hash_including(
        pdf_invoice_subject: "Cours annuels #{subscription.year}-#{subscription.year + 1} - #{subscription.description}"
      ))
    end
  end

  context 'with an external camp registration' do
    let(:camp) { create(:camp, starts_at: Date.new(2026, 10, 20), ends_at: Date.new(2026, 10, 24), open_to_externals: true) }
    let(:subscription) do
      create(
        :camp_registration,
        member:,
        year: camp.year,
        paid_at: Time.current,
        payment_method: :credit_card,
        camps_subscription_attributes: { camp_id: camp.id }
      )
    end

    it 'identifies the stage and external rate' do
      create_invoice.call

      expect(client).to have_received(:create_invoice).with(hash_including(
        pdf_invoice_subject: "Stage - #{camp.title}",
        pdf_description: include('Tarif externe')
      ))
    end
  end
end
