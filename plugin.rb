# name: discourse-maintenance-mode
# about: A simple toggleable maintenance mode plugin for Discourse
# version: 1.0.7
# authors: GamersUnited.pro
# url: https://github.com/GamersUnited-pro/discourse-maintenance-mode

PLUGIN_NAME ||= "discourse-maintenance-mode".freeze
PLUGIN_VERSION ||= "1.0.7".freeze

enabled_site_setting :maintenance_mode_enabled

after_initialize do
  require_dependency "application_controller"
  require 'net/http'
  require 'json'

  module ::DiscourseMaintenanceMode
    class << self
      def latest_release
        @latest_release ||= begin
          url = URI("https://api.github.com/repos/GamersUnited-pro/discourse-maintenance-mode/releases/latest")
          res = Net::HTTP.get_response(url)
          if res.is_a?(Net::HTTPSuccess)
            data = JSON.parse(res.body)
            data["tag_name"]
          else
            nil
          end
        rescue => e
          Rails.logger.warn("Maintenance mode plugin update check failed: #{e.message}")
          nil
        end
      end

      def update_available?
        latest = latest_release
        return false unless latest
        Gem::Version.new(latest.gsub(/^v/, "")) > Gem::Version.new(PLUGIN_VERSION)
      end
    end
  end

  class ::DiscourseMaintenanceMode::Notifier
    def self.notify_if_update_available
      return unless defined?(AdminNotification)
      return unless ::DiscourseMaintenanceMode.update_available?

      AdminNotification.create!(
        notification_type: AdminNotification.types[:custom],
        message: "A new version of Discourse Maintenance Mode is available: #{::DiscourseMaintenanceMode.latest_release}. Please update!"
      )
    end
  end

  # Notify on first web request
  on(:site_setting_changed) do |name, old_value, new_value|
    ::DiscourseMaintenanceMode::Notifier.notify_if_update_available
  end

  # -----------------------------
  # Patch ApplicationController safely
  # -----------------------------
  ::ApplicationController.class_eval do
    before_action :check_maintenance_mode

    def check_maintenance_mode
      return unless SiteSetting.maintenance_mode_enabled

      return if current_user&.admin? || current_user&.moderator?

      allowed_paths = [
        "/login",
        "/logout",
        "/session",
        "/user_activations",
        "/password_resets"
      ]

      return if allowed_paths.any? { |path| request.path.start_with?(path) }
      return if request.format.json? # allow API requests

      render template: "discourse_maintenance_mode/maintenance", layout: false
    end
  end
end
