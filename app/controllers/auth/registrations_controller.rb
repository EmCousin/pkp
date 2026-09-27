# frozen_string_literal: true

module Auth
  class RegistrationsController < BaseController
    before_action :redirect_authenticated_user, only: %i[new create]
    before_action :authenticate_user!, only: %i[edit update confirm_destroy destroy]

    def new
      @user = User.new
      @minimum_password_length = Auth.password_length.begin
    end

    def edit
      @user = Current.user
    end

    def create
      @user = User.new(sign_up_params)
      @minimum_password_length = Auth.password_length.begin

      if @user.save(context: :sign_up)
        destination = after_authentication_path
        sign_in(@user)
        redirect_to destination, notice: t('.success'), status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @user = Current.user

      if @user.update_account(account_attributes, current_password:)
        sign_in(@user) if password_changed?
        redirect_to dashboard_path, notice: t('.success'), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def confirm_destroy
      @user = Current.user
    end

    def destroy
      user = Current.user
      return redirect_to_undeletable_account unless user.destroyable? && user.destroy

      sign_out
      redirect_to new_user_session_path, notice: t('.success'), status: :see_other
    end

    private

    def sign_up_params
      params.expect(user: %i[
                      first_name last_name email email_confirmation password password_confirmation terms_of_service
                    ])
    end

    def account_params
      params.expect(
        user: [
          :first_name, :last_name, :email, :phone_number, :address, :zip_code, :city, :country,
          :password, :password_confirmation, :current_password,
          { contacts_attributes: %i[id email _destroy] }
        ]
      )
    end

    def account_attributes
      @account_attributes ||= account_params.to_h.deep_symbolize_keys.tap do |attributes|
        @current_password = attributes.delete(:current_password)
        attributes.except!(:password, :password_confirmation) unless password_changed?(attributes)
      end
    end

    def current_password
      account_attributes
      @current_password
    end

    def password_changed?(attributes = account_attributes)
      attributes[:password].present? || attributes[:password_confirmation].present?
    end

    def redirect_to_undeletable_account
      redirect_to edit_user_registration_path,
                  alert: t('.finalized_event_registration'),
                  status: :see_other
    end
  end
end
