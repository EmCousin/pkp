# frozen_string_literal: true

module Dashboard
  class MembersController < DashboardController
    before_action :set_member, only: %i[show edit update destroy]
    helper_method :return_path

    def index
      @members = Current.user.members.active.where(platform: Current.platform).order(:first_name, :last_name).with_attached_avatar
    end

    def show; end

    def new
      @member = Current.user.members.new(platform: Current.platform)
    end

    def edit; end

    def create
      @member = Current.user.members.new(member_params.merge(platform: Current.platform))

      if @member.save
        redirect_to(return_path || new_dashboard_subscription_path(member_id: @member.id), notice: t('.success'), status: :see_other)
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @member.update(member_params)
        redirect_to [:dashboard, @member], notice: t('.success'), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @member.deactivate!
      redirect_to %i[dashboard members], notice: t('.success'), status: :see_other
    rescue ActiveRecord::RecordNotDestroyed
      redirect_to [:dashboard, @member], alert: t('.error'), status: :see_other
    end

    private

    def set_member
      @member = Current.user.members.active.find_by!(platform: Current.platform, id: params.expect(:id))
    end

    def member_params
      params.expect(
        member: %i[first_name last_name birthdate
                   contact_name contact_phone_number contact_relationship
                   agreed_to_advertising_right
                   avatar]
      )
    end

    def return_path
      path = url_from(params[:return_to])
      return unless path

      route = Rails.application.routes.recognize_path(path)
      path if route[:controller].start_with?('dashboard/')
    rescue ActionController::RoutingError
      nil
    end
  end
end
