# frozen_string_literal: true

module Dashboard
  class MembersController < DashboardController
    include AccessFilters

    before_action :set_member, only: %i[edit update]

    def new
      @member = current_user.members.new
    end

    def edit; end

    def create
      @member = current_user.members.new(member_params)

      if @member.save
        redirect_to new_dashboard_subscription_path(member_id: @member.id), notice: t('.success')
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @member.update(member_params)
        redirect_to dashboard_index_path, notice: t('.success')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_member
      @member = current_user.members.find(params[:id])
    end

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
