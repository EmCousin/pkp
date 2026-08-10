# frozen_string_literal: true

require 'rails_helper'

describe Subscriptions::Invoiceable, type: :model do
  subject { build :subscription }

  it { is_expected.to respond_to :invoice }
  it { is_expected.to respond_to :credit_notes }
  it { is_expected.to respond_to :billing_invoice }

  it 'creates the billing snapshot and queues it in the payment transaction' do
    subscription = create(:discovery_registration, discovery_session: create(:discovery_session))

    expect { subscription.update!(paid_at: Time.current, payment_method: :credit_card) }
      .to change(Invoice, :count).by(1)
      .and have_enqueued_job(Pennylane::CreateInvoiceJob)

    expect(subscription.billing_invoice).to have_attributes(
      amount: subscription.fee,
      label: subscription.invoice_label,
      description: subscription.invoice_description
    )
  end

  it 'still enqueues after a later save in the same transaction' do
    subscription = create(:discovery_registration, discovery_session: create(:discovery_session))

    expect do
      subscription.transaction do
        subscription.update!(paid_at: Time.current, payment_method: :credit_card)
        subscription.confirmed!
      end
    end.to have_enqueued_job(Pennylane::CreateInvoiceJob)
  end

  it 'does not create an invoice for an unrelated update' do
    subscription = create(:discovery_registration, discovery_session: create(:discovery_session))

    expect { subscription.update!(status: :confirmed) }.not_to change(Invoice, :count)
  end

  it 'does not reserve an invoice before payment' do
    subscription = create(:discovery_registration, discovery_session: create(:discovery_session))

    expect { subscription.request_billing_invoice! }.not_to change(Invoice, :count)
    expect(subscription.billing_invoice).to be_nil
  end

  it 'prevents reverting payment as soon as synchronization is requested' do
    subscription = create(
      :discovery_registration,
      discovery_session: create(:discovery_session),
      paid_at: Time.current
    )

    expect(subscription.mark_as_not_paid!).to be false
    expect(subscription).to be_paid
    expect(subscription.errors.of_kind?(:base, :pennylane_invoice_finalized)).to be true
  end

  it 'prevents destroying a subscription or changing its courses after invoicing is requested' do
    category = create(:category)
    initial_course = create(:course, category:)
    added_course = create(:course, category:)
    subscription = create(:subscription, courses: [initial_course], paid_at: Time.current)
    course_subscription = subscription.courses_subscriptions.first
    added_course_subscription = CoursesSubscription.new(subscription:, course: added_course)

    expect(subscription.destroy).to be false
    expect(course_subscription.destroy).to be false
    expect(added_course_subscription.save).to be false
    expect(subscription).to be_persisted
    expect(course_subscription).to be_persisted
  end

  it 'prevents cascading deletion through the member and account holder' do
    user = create(:user)
    member = create(:member, user:)
    subscription = create(:subscription, member:, courses: [create(:course)], paid_at: Time.current)

    expect(member.destroy).to be false
    expect(user.destroy).to be false
    expect(subscription.reload).to be_persisted
  end

  it 'snapshots annual course details in the annual model' do
    subscription = create(:subscription, courses: [create(:course)], paid_at: Time.current)

    expect(subscription.billing_invoice.label).to eq(
      "Cours annuels #{subscription.year}-#{subscription.year + 1} - #{subscription.description}"
    )
  end

  it 'snapshots discovery session details in the discovery model' do
    session = create(:discovery_session, starts_at: Time.zone.local(2026, 9, 12, 14))
    subscription = create(:discovery_registration, discovery_session: session, paid_at: Time.current)

    expect(subscription.billing_invoice.description).to include(I18n.l(session.occurrence_date, format: :long))
  end

  it 'snapshots camp dates and the external rate in the camp model' do
    camp = create(:camp, starts_at: Date.new(2026, 10, 20), ends_at: Date.new(2026, 10, 24), open_to_externals: true)
    subscription = create(
      :camp_registration,
      year: camp.year,
      paid_at: Time.current,
      camps_subscription_attributes: { camp_id: camp.id }
    )

    expect(subscription.billing_invoice.description).to include('Tarif externe', '20 octobre 2026', '24 octobre 2026')
  end
end
