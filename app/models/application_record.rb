# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def next
    self.class.where('id > ?', id).order(:id).first || self.class.first
  end

  def previous
    self.class.where('id < ?', id).order(id: :desc).first || self.class.last
  end
end
