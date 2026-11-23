require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Aquatanks
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # No Active Storage routes: their file links work for anyone who has them, which
    # would leak private tanks' photos. Pictures are served by our own controllers
    # (ApplicationController#send_photo) after a visibility check. Uploads go
    # through normal forms, so direct-upload routes aren't needed either.
    config.active_storage.draw_routes = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
