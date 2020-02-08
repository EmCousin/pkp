require 'rails_helper'

describe SubscriptionsMailbox, type: :mailbox do
  let(:user) { create :user }
  let(:email) { user.email }
  let(:mail_attributes) do
    {
      to: 'inscriptions@parkourparis.fr',
        from: email,
        subject: "Fwd: Status update?",
        body: <<~BODY
          --- Begin forwarded message ---
          From: Frank Holland <frank@microsoft.com>

          What's the status?
        BODY
    }
  end

  it 'is expected to catch an inbound email' do
    expect do
      receive_inbound_email_from_mail(mail_attributes)
    end.to change(ActionMailbox::InboundEmail, :count).by 1
  end

  context 'when the user does not exist' do
    let(:email) { 'invalidemail@example.com' }

    it 'should bounce with UserMailer#missing' do
      expect(UserMailer).to receive(:missing).with(instance_of(ActionMailbox::InboundEmail)).and_call_original
    end

    after { receive_inbound_email_from_mail(mail_attributes) }
  end
end
