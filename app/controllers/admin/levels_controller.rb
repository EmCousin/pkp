# frozen_string_literal: true

module Admin
  class LevelsController < BaseController
    before_action :set_member!

    def update
      @member.update!(level: level_param)
      redirect_back_or_to [:admin, @member], notice: t('.success'), status: :see_other
    end

    private

    def set_member!
      @member = Member.find(params[:member_id])
    end

    def level_param
      member_params.require(:level)
    end

    def member_params
      params.expect(member: [:level])
    end
  end
end
