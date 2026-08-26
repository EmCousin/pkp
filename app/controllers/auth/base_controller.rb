# frozen_string_literal: true

module Auth
  class BaseController < ApplicationController
    private

    def redirect_authenticated_user
      return unless Current.user

      redirect_to signed_in_root_path,
                  notice: t('auth.failure.already_authenticated'),
                  status: :see_other
    end
  end
end
