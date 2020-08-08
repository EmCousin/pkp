require 'rails_helper'

describe Users::Chargeable, type: :model do
  let(:user) { build :user }

  subject { user }

  it "creates a stripe customer id" do
    expect {
      subject.save!
    }.to(
      have_enqueued_job(Stripe::CreateCustomerJob)
        .on_queue('default')
        .with(subject)
    )
  end
end
