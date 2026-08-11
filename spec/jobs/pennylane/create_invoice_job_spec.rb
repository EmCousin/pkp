# frozen_string_literal: true

require 'rails_helper'

describe Pennylane::CreateInvoiceJob, type: :job do
  let(:subscription) do
    create(:discovery_registration, discovery_session: create(:discovery_session), paid_at: Time.current)
  end
  let(:invoice) { subscription.billing_invoice }
  let(:sync_token) { invoice.sync_token }
  let(:service) { instance_double(Pennylane::CreateInvoice, call: true) }

  before do
    allow(Pennylane::CreateInvoice).to receive(:new).with(invoice, sync_token:).and_return(service)
  end

  it 'claims and synchronizes a pending invoice' do
    described_class.perform_now(invoice, sync_token)

    expect(service).to have_received(:call)
    expect(invoice.reload).to be_processing
  end

  it 'does not run a concurrent synchronization' do
    invoice.update!(state: :processing)

    described_class.perform_now(invoice, sync_token)

    expect(service).not_to have_received(:call)
  end

  it 'marks a permanent Pennylane error as failed' do
    allow(service).to receive(:call).and_raise(Pennylane::Error, 'Invalid invoice')

    described_class.perform_now(invoice, sync_token)

    expect(invoice.reload).to be_failed
    expect(invoice.error).to eq('Invalid invoice')
  end

  it 'keeps a transient failure retryable without exposing a terminal error' do
    allow(service).to receive(:call).and_raise(Pennylane::RetryableError, 'Unavailable')

    expect { described_class.perform_now(invoice, sync_token) }
      .to have_enqueued_job(described_class).with(invoice, sync_token)
    expect(invoice.reload).to be_retrying
    expect(invoice.error).to be_nil
  end

  it 'ignores a job from an obsolete synchronization chain' do
    invoice.update_columns(sync_token: SecureRandom.uuid)

    described_class.perform_now(invoice, sync_token)

    expect(service).not_to have_received(:call)
  end
end
