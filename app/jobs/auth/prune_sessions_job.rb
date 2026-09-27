# frozen_string_literal: true

module Auth
  class PruneSessionsJob < ApplicationJob
    def perform
      Auth::Session.expired.delete_all
    end
  end
end
