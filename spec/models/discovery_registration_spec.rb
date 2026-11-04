# frozen_string_literal: true

require 'rails_helper'

describe DiscoveryRegistration, type: :model do
  it 'serializes confirmation behind the course lock', :concurrent do
    discovery_session = create(:discovery_session)
    registration = create(:discovery_registration,
                          discovery_session:,
                          member: create(:member, platform: discovery_session.platform),
                          fee: discovery_session.price)
    locked = Queue.new
    release = Queue.new
    locker = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Course.find(registration.discovery_session.course_id).with_lock do
          locked << true
          release.pop
        end
      end
    end
    locked.pop

    expect do
      ActiveRecord::Base.connection.execute("SET lock_timeout = '100ms'")
      described_class.find(registration.id).confirm!
    end.to raise_error(ActiveRecord::LockWaitTimeout)
    expect(registration.reload).to be_pending

    release << true
    locker.join
    described_class.find(registration.id).confirm!
    expect(registration.reload).to be_confirmed
  ensure
    release << true if release && locker&.alive?
    locker&.join
    ActiveRecord::Base.connection.execute('SET lock_timeout = DEFAULT')
  end
end
