# frozen_string_literal: true

module Contacts
  class ConfirmationsController < ApplicationController
    before_action :set_contact

    def show
      @contact.update!(confirmed_at: Time.current) unless @contact.confirmed_at?
    end

    def destroy
      @contact.destroy!
      redirect_to root_path, notice: t('.success')
    end

    private

    def set_contact
      @contact = Contact.find_signed(params[:contact_id], purpose: :confirmation)
    end
  end
end
