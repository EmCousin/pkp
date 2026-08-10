# frozen_string_literal: true

require 'rails_helper'

describe Pennylane::SyncMissingInvoicesJob, type: :job do
  it 're-enqueues paid invoice requests that were lost before reaching the queue' do
    subscription = create(:discovery_registration, discovery_session: create(:discovery_session))
    subscription.update_columns(paid_at: Time.current, pennylane_invoice_requested_at: Time.current)

    expect { described_class.perform_now }
      .to have_enqueued_job(Pennylane::CreateInvoiceJob).with(subscription)
  end

  it 'ignores completed and permanently failed synchronizations' do
    discovery_session = create(:discovery_session)
    completed = create(:discovery_registration, discovery_session:)
    completed.update_columns(
      paid_at: Time.current,
      pennylane_invoice_requested_at: Time.current,
      pennylane_invoice_id: 123
    )
    failed = create(:discovery_registration, discovery_session:)
    failed.update_columns(
      paid_at: Time.current,
      pennylane_invoice_requested_at: Time.current,
      pennylane_invoice_error: 'Invalid customer'
    )

    expect { described_class.perform_now }
      .not_to have_enqueued_job(Pennylane::CreateInvoiceJob)
  end
end
