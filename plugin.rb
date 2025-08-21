# name: discourse-maintenance-mode
# about: A simple toggleable maintenance mode plugin for Discourse
# version: 1.0.3
# authors: GamersUnited.pro
# url: https://github.com/GamersUnited-pro/discourse-maintenance-mode

PLUGIN_NAME ||= "discourse-maintenance-mode".freeze
PLUGIN_VERSION ||= "1.0.3".freeze

enabled_site_setting :maintenance_mode_enabled

after_initialize do
  require_dependency "application_controller"
  require 'net/http'
  require 'json'

  # -----------------------------
  # Module for release checking
  # -----------------------------
  module ::DiscourseMaintenanceMode
    class << self
      # Fetch latest release tag from GitHub
      def latest_release
        url = URI("https://api.github.com/repos/GamersUnited-pro/discourse-maintenance-mode/releases/latest")
        res = Net::HTTP.get_response(url)
        return nil unless res.is_a?(Net::HTTPSuccess)
        data = JSON.parse(res.body)
        data["tag_name"]
      rescue
        nil
      end

      # Compare current plugin version to latest release
      def update_available?
        latest = latest_release
        return false unless latest
        Gem::Version.new(latest.gsub(/^v/, "")) > Gem::Version.new(PLUGIN_VERSION)
      end
    end
  end

  # -----------------------------
  # Admin notification if update is available
  # -----------------------------
  if ::DiscourseMaintenanceMode.update_available?
    AdminNotification.create!(
      notification_type: AdminNotification.types[:custom],
      message: "A new version of Discourse Maintenance Mode is available: #{::DiscourseMaintenanceMode.latest_release}. Please update!"
    )
  end

  # -----------------------------
  # Patch ApplicationController for maintenance mode
  # -----------------------------
  class ::ApplicationController
    before_action :check_maintenance_mode

    def check_maintenance_mode
      return unless SiteSetting.maintenance_mode_enabled

      # Allow admins and moderators full access
      return if current_user && (current_user.admin? || current_user.moderator?)

      # Allow login, registration, and activation pages during maintenance
      allowed_paths = [
        "/login",
        "/logout",
        "/session",
        "/users",
        "/user_activations",
        "/password_resets",
        "/site_settings",
        "/notifications"
      ]
      return if allowed_paths.any? { |path| request.path.start_with?(path) }

      # Render maintenance page template
      render template: "discourse_maintenance_mode/maintenance", layout: false
    end
  end
end
