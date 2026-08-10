# frozen_string_literal: true

require 'rails_helper'

describe Subscriptions::Invoiceable, type: :model do
  subject { build :subscription }

  it { is_expected.to respond_to :invoice }
  it { is_expected.to respond_to :credit_notes }

  it { is_expected.to respond_to :credit_note_amount }
  it { is_expected.to respond_to 'credit_note_amount' }

  it 'queues a Pennylane invoice when payment is recorded' do
    discovery_session = create(:discovery_session)
    subscription = create(:discovery_registration, discovery_session:)

    expect { subscription.update!(paid_at: Time.current, payment_method: :credit_card) }
      .to have_enqueued_job(Pennylane::CreateInvoiceJob).with(subscription)
    expect(subscription.pennylane_invoice_requested_at).to be_present
  end

  it 'does not queue a Pennylane invoice for an unrelated update' do
    subscription = create(:discovery_registration, discovery_session: create(:discovery_session))

    expect { subscription.update!(status: :confirmed) }
      .not_to have_enqueued_job(Pennylane::CreateInvoiceJob)
  end

  it 'prevents reverting a payment after the Pennylane invoice is finalized' do
    subscription = create(
      :discovery_registration,
      discovery_session: create(:discovery_session),
      paid_at: Time.current,
      pennylane_invoice_id: 123
    )

    expect(subscription.mark_as_not_paid!).to be false
    expect(subscription).to be_paid
    expect(subscription.errors.of_kind?(:base, :pennylane_invoice_finalized)).to be true
  end
end
