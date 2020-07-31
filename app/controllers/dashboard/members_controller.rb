# frozen_string_literal: true

module Dashboard
  class MembersController < DashboardController
    include AccessFilters

    def new
      @member = current_user.members.new
    end

    def create
      @member = current_user.members.new(member_params)

      if @member.save
        redirect_to new_dashboard_subscription_path(member_id: @member.id), notice: t('.success')
      else
        render :new
      end
    end

    private

    def member_params
      params.require(:member).permit(
        :first_name, :last_name, :birthdate,
        :contact_name, :contact_phone_number, :contact_relationship,
        :agreed_to_advertising_right,
        :avatar
      )
    end
  end
end
