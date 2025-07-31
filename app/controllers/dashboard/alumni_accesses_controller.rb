# frozen_string_literal: true

module Dashboard
  class AlumniAccessesController < DashboardController
    before_action :filter_alumni_time!

    def new
      @alumni_access = AlumniAccess.new
    end

    def create
      @alumni_access = AlumniAccess.new(alumni_access_params)
      if @alumni_access.valid?
        session[:alumni_authenticated] = true
        redirect_to %i[new dashboard subscription], status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def filter_alumni_time!
      redirect_to :root, alert: t('.not_yet_open') unless alumni_time?
    end

    def alumni_access_params
      params.expect(alumni_access: %i[username password])
    end
  end
end
