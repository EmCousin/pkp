# frozen_string_literal: true

module Pennylane
  class Error < StandardError
    attr_reader :status

    def initialize(message, status: nil)
      @status = status
      super(message)
    end

    def conflict?
      status == 409
    end
  end
end
