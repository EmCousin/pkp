# frozen_string_literal: true

module Dashboard
  class AlumniAccessesController < DashboardController
    def new
      @alumni_access = AlumniAccess.new
    end

    def create
      @alumni_access = AlumniAccess.new(alumni_access_params)
      if @alumni_access.valid?
        session[:alumni_authenticated] = true
        redirect_to %i[new dashboard subscription]
      else
        render :new, status: :unauthorized
      end
    end

    private

    def alumni_access_params
      params.require(:alumni_access).permit(:username, :password)
    end
  end
end
