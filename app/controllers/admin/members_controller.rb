# frozen_string_literal: true

require 'csv'

module Admin
  class MembersController < AdminController
    before_action :set_members, only: :index
    before_action :set_member, only: %i[show edit update destroy]

    def index
      respond_to do |format|
        format.html
        format.csv do
          respond_with_csv(:index)
        end
      end
    end

    def show; end

    def new
      @member = Member.new
    end

    def create
      @member = Member.new(member_params)
      @member.user.terms_of_service = true

      if @member.save
        redirect_to %i[admin members], notice: t('.success'), status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @member.update(member_params)
        redirect_back_or_to %i[admin members], notice: t('.success')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @member.destroy
      redirect_to %i[admin members], notice: t('.success')
    end

    private

    def set_member
      @member = Member.find(params[:id])
    end

    def member_params
      params.require(:member).permit(
        :level, :first_name, :last_name, :birthdate,
        :contact_name, :contact_phone_number, :contact_relationship,
        :avatar,
        :agreed_to_advertising_right,
        user_attributes: %i[id email password address zip_code city country phone_number admin]
      )
    end

    def set_members # rubocop:disable Metrics/AbcSize
      members = Member.search(params[:q])
      members = members.for_category(params[:category]) if params[:category].present?
      members = members.where(level: params[:level]) if params[:level].present?
      members = members.for_subscription_year(params[:subscription_year]) if params[:subscription_year].present?
      members = members.page(params[:page]).per(25) unless params[:no_paginate].present?
      @members = members.includes(:user, :contacts).with_attached_avatar
    end

    def respond_with_csv(view_name)
      response.headers['Content-Type'] = Mime[:csv]
      response.headers['Content-Disposition'] = 'attachment; filename=members.csv'
      render body: render_to_string(view_name).squish.gsub('<br/>', "\n")
    end
  end
end
