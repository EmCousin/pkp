# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  extend ActiveRecord::HumanEnumName

  def next
    self.class.where('created_at > ?', created_at).order(:created_at).first || self.class.first
  end

  def previous
    self.class.where('created_at < ?', created_at).order(created_at: :desc).first || self.class.last
  end
end
