# frozen_string_literal: true

module Dashboard
  class MedicalCertificatesController < DashboardController
    def edit
      @subscription = current_user.subscriptions.find_by!(id: params[:subscription_id], year: Time.now.year)
    end

    def update
      @subscription = current_user.subscriptions.find_by!(id: params[:subscription_id], year: Time.now.year)
      if @subscription.update(subscription_params)
        redirect_to dashboard_index_path, notice: t('.edit_success')
      else
        render :edit
      end
    end

    private

    def subscription_params
      params.require(:subscription).permit(
        :medical_certificate
      )
    end
  end
end