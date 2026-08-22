# frozen_string_literal: true

require 'rails_helper'

describe Pennylane::CreateInvoice, type: :service do
  subject(:create_invoice) { described_class.new(invoice, sync_token:, client:) }

  let(:client) { instance_double(Pennylane::Client) }
  let(:user) { create(:user) }
  let(:member) { create(:member, user:) }
  let(:discovery_session) { create(:discovery_session, starts_at: Time.zone.local(2026, 9, 12, 14), price: 36) }
  let(:subscription) do
    create(
      :discovery_registration,
      member:,
      discovery_session:,
      paid_at: Time.current,
      payment_method: :credit_card,
      stripe_payment_intent_id: 'pi_test_123'
    )
  end
  let(:invoice) { subscription.billing_invoice.tap { it.claim!(it.sync_token) } }
  let(:sync_token) { invoice.sync_token }
  let(:customer) { { 'id' => 123 } }
  let(:created_invoice) { { 'id' => 456, 'invoice_number' => 'F20260001' } }
  let(:unpaid_invoice) { created_invoice.merge('paid' => false, 'public_file_url' => nil) }
  let(:paid_invoice) do
    created_invoice.merge('paid' => true, 'public_file_url' => 'https://files.example.test/invoice.pdf')
  end

  before do
    allow(client).to receive(:find_customer).with("pkp-user-#{user.id}").and_return(customer)
    allow(client).to receive(:update_customer).with(123, anything)
    allow(client).to receive(:find_invoice).with("pkp-invoice-#{invoice.id}").and_return(nil)
    allow(client).to receive(:create_invoice).and_return(created_invoice)
    allow(client).to receive(:invoice).with(456).and_return(unpaid_invoice, paid_invoice)
    allow(client).to receive(:mark_invoice_as_paid).with(456)
    allow(client).to receive(:download).with('https://files.example.test/invoice.pdf').and_return('%PDF invoice')
  end

  it 'creates a finalized paid invoice from the immutable tax-inclusive snapshot' do
    create_invoice.call

    expect(client).to have_received(:create_invoice).with(hash_including(
      customer_id: 123,
      draft: false,
      external_reference: "pkp-invoice-#{invoice.id}",
      pdf_invoice_subject: "Cours découverte - #{discovery_session.course.title}",
      transaction_reference: {
        banking_provider: 'stripe',
        provider_field_name: 'payment_id',
        provider_field_value: 'pi_test_123'
      },
      invoice_lines: [hash_including(
        raw_currency_unit_price: '30.0',
        vat_rate: 'FR_200',
        quantity: 1
      )]
    ))
    expect(client).to have_received(:mark_invoice_as_paid).with(456)
    expect(invoice.reload).to be_completed
    expect(invoice).to have_attributes(external_id: 456, number: 'F20260001', error: nil)
    expect(invoice.document).to be_attached
  end

  it 'uses the snapshotted account holder details' do
    original_name = invoice.customer_snapshot.fetch('first_name')
    user.update!(first_name: 'Changed')

    create_invoice.call

    expect(client).to have_received(:update_customer).with(123, hash_including(first_name: original_name))
    expect(client).to have_received(:update_customer).with(123, hash_including(first_name: 'Changed'))
  end

  it 'creates and stores a missing Pennylane customer' do
    allow(client).to receive(:find_customer).and_return(nil)
    allow(client).to receive(:create_customer).and_return(customer)

    create_invoice.call

    expect(client).to have_received(:create_customer).with(hash_including(
      first_name: user.first_name,
      last_name: user.last_name,
      external_reference: "pkp-user-#{user.id}"
    ))
    expect(user.reload.pennylane_customer_id).to eq(123)
  end

  it 'resumes an existing external invoice instead of creating a duplicate' do
    invoice.update_column(:external_id, 456)

    create_invoice.call

    expect(client).not_to have_received(:find_invoice)
    expect(client).not_to have_received(:create_invoice)
    expect(client).to have_received(:update_customer).with(123, hash_including(first_name: user.first_name))
    expect(invoice.document).to be_attached
  end

  it 'recovers a duplicate reference returned as 422' do
    allow(client).to receive(:find_invoice)
      .with("pkp-invoice-#{invoice.id}")
      .and_return(nil, nil, created_invoice)
    allow(client).to receive(:create_invoice)
      .and_raise(Pennylane::Error.new(
                   'Unprocessable entity',
                   status: 422,
                   response_body: { details: { field: 'external_reference', issue: 'already exists' } }
                 ))

    create_invoice.call

    expect(client).to have_received(:find_invoice).exactly(3).times
    expect(invoice.reload.external_id).to eq(456)
  end

  it 'refuses synchronization if the local payment was reverted outside the domain guard' do
    subscription.update_column(:paid_at, nil)

    expect { create_invoice.call }.to raise_error(Pennylane::Error, 'Le paiement de la facture a été annulé')
  end

  it 'finishes a queued invoice after its member is tombstoned' do
    invoice
    member.remove!
    subscription.reload

    create_invoice.call

    expect(invoice.reload).to be_completed
    expect(client).to have_received(:find_customer).with("pkp-user-#{user.id}")
    expect(client).to have_received(:update_customer).once
  end
end
