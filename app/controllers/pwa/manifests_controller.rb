# frozen_string_literal: true

module Pwa
  class ManifestsController < ApplicationController
    layout false

    before_action :set_icons

    ICON_SIZES = [48, 72, 96, 128, 192, 384, 512].freeze

    def show
      render json: {
        short_name: "PKP",
        name: "Parkour Paris",
        icons: @icons,
        start_url: "/?source=pwa",
        background_color: "#343a40",
        display: "standalone",
        scope: "/",
        theme_color: "#343a40",
        description: "Parkour Paris subscriptions",
        screenshots: [
          {
            src: "/assets/screenshot.png",
            type: Mime[:png].to_s,
            sizes: "1920x1326"
          }
        ]
      }
    end

    private

    def set_icons
      @icons = ICON_SIZES.map do |size|
        {
          src: "/assets/pkp-#{size}.png",
          type: Mime[:png].to_s,
          sizes: "#{size}x#{size}",
          purpose: "any maskable"
        }
      end
    end
  end
end
