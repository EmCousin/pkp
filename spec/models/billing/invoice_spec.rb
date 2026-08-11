# frozen_string_literal: true

require 'rails_helper'

describe Billing::Invoice, type: :model do
  subject(:invoice) do
    create(
      :discovery_registration,
      discovery_session: create(:discovery_session),
      paid_at: Time.current
    ).request_billing_invoice!
  end

  it { is_expected.to belong_to(:invoiceable) }
  it { is_expected.to define_enum_for(:state).backed_by_column_of_type(:string) }

  it 'uses the Billing table prefix' do
    expect(Billing).to be_abstract_class
    expect(described_class.table_name).to eq('billing_invoices')
  end

  it 'serializes concurrent claims' do
    expect(invoice.claim!(invoice.sync_token)).to be true
    expect(invoice.claim!(invoice.sync_token)).to be false
  end

  it 'can be retried after a terminal failure' do
    old_token = invoice.sync_token
    invoice.claim!(old_token)
    invoice.fail!(old_token, StandardError.new('Failure'))

    expect { invoice.retry! }.to have_enqueued_job(Pennylane::CreateInvoiceJob).with(invoice, kind_of(String))
    expect(invoice.reload).to be_pending
    expect(invoice.error).to be_nil
    expect(invoice.sync_token).not_to eq(old_token)
  end

  it 'does not let an obsolete synchronization overwrite a newer one' do
    old_token = invoice.sync_token
    invoice.update_columns(updated_at: 16.minutes.ago)
    invoice.recover!

    expect(invoice.fail!(old_token, StandardError.new('Late failure'))).to be false
    expect(invoice.reload).to be_pending
  end

  it 'fences the original worker when recovering stale processing' do
    old_token = invoice.sync_token
    invoice.update_columns(state: :processing, updated_at: 16.minutes.ago)

    expect(invoice.claim!(old_token)).to be false
    invoice.recover!

    expect(invoice.reload.sync_token).not_to eq(old_token)
    expect(invoice.claim!(invoice.sync_token)).to be true
  end

  it 'does not revive a completed synchronization' do
    token = invoice.sync_token
    invoice.claim!(token)
    invoice.complete!(token, 'id' => 456, 'invoice_number' => 'F20260001')

    expect(invoice.claim!(token)).to be false
    expect(invoice.retry!).to be_nil
  end

  it 'can terminate an exhausted retry chain' do
    token = invoice.sync_token
    invoice.claim!(token)
    invoice.mark_retrying!(token)

    expect(invoice.fail!(token, StandardError.new('Exhausted'))).to be true
    expect(invoice.reload).to be_failed
  end
end
