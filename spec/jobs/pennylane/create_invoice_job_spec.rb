require 'rails_helper'

describe Pennylane::CreateInvoiceJob, type: :job do
  let(:subscription) do
    create(:discovery_registration, discovery_session: create(:discovery_session), paid_at: Time.current)
  end
  let(:service) { instance_double(Pennylane::CreateInvoice, call: true) }

  before do
    allow(Pennylane::CreateInvoice).to receive(:new).with(subscription).and_return(service)
  end

  it 'synchronizes a paid registration' do
    described_class.perform_now(subscription)

    expect(service).to have_received(:call)
  end

  it 'does nothing if the payment was reverted before the job runs' do
    subscription.update_columns(paid_at: nil, payment_method: nil)

    described_class.perform_now(subscription)

    expect(service).not_to have_received(:call)
  end

  it 'stores the last Pennylane error' do
    allow(service).to receive(:call).and_raise(Pennylane::Error, 'Invalid invoice')

    expect { described_class.perform_now(subscription) }.to raise_error(Pennylane::Error, 'Invalid invoice')
    expect(subscription.reload.pennylane_invoice_error).to eq('Invalid invoice')
  end
end
