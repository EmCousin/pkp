# frozen_string_literal: true

module Admin
  class MembersController < AdminController
    before_action :set_member, only: %i[show edit update destroy]

    def index
      @search = params[:q]&.downcase
      @members = (@search.present? ? Member.search(@search) : Member)
                 .page(params[:page]).per(50).includes(:user)
    end

    def show; end

    def new
      @member = Member.new
    end

    def create
      @member = Member.new(member_params)
      @member.user.terms_of_service = true
      # @member.user.skip_confirmation!
      if @member.save
        redirect_to admin_members_path, notice: 'Membre créé avec succès !'
      else
        render :new
      end
    end

    def edit; end

    def update
      if @member.update(member_params)
        redirect_to admin_members_path, notice: 'Membre modifié avec succès !'
      else
        render :edit
      end
    end

    def destroy
      @member.destroy
      redirect_to admin_members_path, notice: 'Membre supprimé avec succès !'
    end

    private

    def set_member
      @member = Member.find(params[:id])
    end

    def member_params
      params.require(:member).permit(
        :first_name, :last_name, :birthdate,
        :contact_name, :contact_phone_number, :contact_relationship,
        :avatar,
        :agreed_to_advertising_right,
        user_attributes: %i[id email password address zip_code city country phone_number admin]
      )
    end
  end
end
