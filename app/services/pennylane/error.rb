# frozen_string_literal: true

module Pennylane
  class Error < StandardError
    attr_reader :response_body, :status

    def initialize(message, status: nil, response_body: nil)
      @status = status
      @response_body = response_body
      super(message)
    end

    def duplicate_reference?
      return true if status == 409
      return false unless status == 422

      details = [message, response_body].compact.join(' ')
      details.match?(/external.?reference/i) && details.match?(/duplicate|already exists|already been taken|déjà|unique/i)
    end
  end
end
