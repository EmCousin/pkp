# frozen_string_literal: true

module Auth
  class BaseController < ApplicationController
    private

    def redirect_authenticated_user
      return unless user_signed_in?

      redirect_to signed_in_root_path,
                  notice: t('auth.failure.already_authenticated'),
                  status: :see_other
    end

    def enqueue_auth_instructions(job, email)
      job.perform_later(email)
    rescue StandardError => e
      Rails.error.report(e, handled: true, context: { job: job.name })
    end
  end
end
