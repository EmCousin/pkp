# frozen_string_literal: true

require 'rails_helper'

describe Pennylane::SyncMissingInvoicesJob, type: :job do
  let(:discovery_session) { create(:discovery_session) }

  it 're-enqueues stale pending, processing and retrying invoices' do
    pending_invoice = create_invoice(state: :pending)
    processing_invoice = create_invoice(state: :processing)
    retrying_invoice = create_invoice(state: :retrying, stale_for: 2.hours + 1.minute)

    expect { described_class.perform_now }
      .to have_enqueued_job(Pennylane::CreateInvoiceJob).with(pending_invoice, kind_of(String))
      .and have_enqueued_job(Pennylane::CreateInvoiceJob).with(processing_invoice, kind_of(String))
      .and have_enqueued_job(Pennylane::CreateInvoiceJob).with(retrying_invoice, kind_of(String))

    expect([pending_invoice, processing_invoice, retrying_invoice].map { it.reload.sync_token }).to all(be_present)
  end

  it 'ignores recent, completed and failed invoices' do
    create_invoice(state: :pending, stale: false)
    create_invoice(state: :retrying)
    create_invoice(state: :completed)
    create_invoice(state: :failed)

    expect { described_class.perform_now }
      .not_to have_enqueued_job(Pennylane::CreateInvoiceJob)
  end

  def create_invoice(state:, stale: true, stale_for: 16.minutes)
    subscription = create(:discovery_registration, discovery_session:, paid_at: Time.current)
    invoice = subscription.request_billing_invoice!
    invoice.update_columns(state:, updated_at: stale ? stale_for.ago : Time.current)
    invoice
  end
end
