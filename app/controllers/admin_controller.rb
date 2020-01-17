# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_current_user_is_admin!

  def index; end

  private

  def ensure_current_user_is_admin!
    return if current_user.admin

    sign_out current_user
    redirect_to after_sign_out_path_for(:user)
  end
end
