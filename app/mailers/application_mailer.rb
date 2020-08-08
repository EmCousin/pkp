# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'inscriptions@parkourparis.fr'
  layout 'mailer'
end
