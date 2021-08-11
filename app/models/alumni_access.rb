# frozen_string_literal: true

class AlumniAccess
  include ActiveModel::Model

  attr_accessor :username, :password

  validates :username, :password, presence: true

  validate :authentication, if: %i[username? password?]

  private

  def username?
    username.present?
  end

  def password?
    password.present?
  end

  def authentication
    errors.add(:username, :invalid) if username != Rails.application.credentials.basic_auth[:username]

    errors.add(:password, :invalid) if password != Rails.application.credentials.basic_auth[:password]
  end
end
