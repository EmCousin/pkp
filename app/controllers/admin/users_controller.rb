# frozen_string_literal: true

module Admin
  class UsersController < AdminController
    def index
      @users = User.page(params[:page]).per(1)
    end

    def show
      @user = User.find(params[:id])
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_users_path, notice: 'Membre créé avec succès !'
      else
        render :new
      end
    end

    def edit
      @user = User.find(params[:id])
    end

    def update
      @user = User.find(params[:id])
      if @user.update(user_params)
        redirect_to admin_users_path, notice: 'Membre modifié avec succès !'
      else
        render :edit
      end
    end

    def destroy
      @user = User.find(params[:id])
      @user.destroy
      redirect_to admin_users_path, notice: 'Membre supprimé avec succès !'
    end

    private

    def user_params
      params.require(:user).permit(
        :email, :password, :first_name, :last_name,
        :birthdate, :phone_number, :address, :zip_code, :city, :country,
        :contact_name, :contact_phone_number, :contact_relationship,
        :agreed_to_publicity_right, :avatar
      )
    end
  end
end
