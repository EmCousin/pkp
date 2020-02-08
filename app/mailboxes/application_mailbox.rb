# frozen_string_literal: true

class ApplicationMailbox < ActionMailbox::Base
  SUBSCRIPTIONS_MATCHER = /inscriptions@parkourparis.fr/i.freeze

  # routing /something/i => :somewhere
  routing SUBSCRIPTIONS_MATCHER => :subscriptions
end
