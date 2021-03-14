# frozen_string_literal: true

class TurboController < ApplicationController
  class Responder < ActionController::Responder
    def to_turbo_stream
      controller.render(options.merge(formats: :html))
    rescue ActionView::MissingTemplate => e
      raise(e) if get?

      if has_errors? && default_action
        render rendering_options.merge(formats: :html, status: :unprocessable_entity)
      else
        redirect_to Rails.application.routes.url_helpers.root_path
      end
    end
  end

  self.responder = Responder
  respond_to :html, :turbo_stream

  def is_flashing_format? # rubocop:disable Naming/PredicateName
    return true if request.format == :turbo_stream

    request.respond_to?(:flash) && is_navigational_format?
  end
end
