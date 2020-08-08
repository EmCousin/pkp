require 'rails_helper'

describe Subscriptions::Invoiceable, type: :model do
  subject { build :subscription }

  it { is_expected.to respond_to :invoice }
  it { is_expected.to respond_to :credit_notes }

  it { is_expected.to respond_to :credit_note_amount }
  it { is_expected.to respond_to 'credit_note_amount' }
end
