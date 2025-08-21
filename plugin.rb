# plugins/discourse-maintenance-mode/plugin.rb
# frozen_string_literal: true

enabled_site_setting :maintenance_mode_enabled

after_initialize do
  require_dependency "application_controller"

  class ::ApplicationController
    before_action :check_maintenance_mode

    def check_maintenance_mode
      return unless SiteSetting.maintenance_mode_enabled

      # Allow admins and moderators full access
      return if current_user && (current_user.admin? || current_user.moderator?)

      # Allow login and registration pages even during maintenance
      allowed_paths = [
        "/login",
        "/logout",
        "/session",
        "/users",
        "/user_activations",
        "/password_resets",
        "/site_settings",
        "/notifications" # you can add more if needed
      ]
      return if allowed_paths.any? { |path| request.path.start_with?(path) }

      # Render maintenance message page
      render template: "discourse_maintenance_mode/maintenance", layout: false
    end
  end
end
