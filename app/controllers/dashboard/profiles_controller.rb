module Dashboard
  class ProfilesController < DashboardController

    def edit; end

    def update
      if current_user.update(user_params)
        redirect_to dashboard_index_path, notice: t('.edit_success')
      else
        render :edit
      end
    end
    private

    def user_params
      params.require(:user).permit(
        :email, :first_name, :last_name,
        :birthdate, :phone_number, :address, :zip_code, :city, :country,
        :contact_name, :contact_phone_number, :contact_relationship,
        :agreed_to_publicity_right, :avatar
      )
    end
  end
end
