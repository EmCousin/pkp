# frozen_string_literal: true

module MembersHelper
  def member_level_text(level)
    I18n.t("activerecord.attributes.member.levels.#{level}")
  end
end
