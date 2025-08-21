# frozen_string_literal: true

# name: discourse-maintenance-mode
# about: Toggleable maintenance mode with stylish page + admin-only update notifications
# version: 1.0.15
# authors: GamersUnited.pro
# url: https://github.com/GamersUnited-pro/discourse-maintenance-plugin

enabled_site_setting :maintenance_mode_enabled

module ::DiscourseMaintenancePlugin
  PLUGIN_NAME = "discourse-maintenance-plugin"
  PLUGIN_VERSION = "1.0.15"
  UPDATE_STORE_KEY = "last_notified_version"
end

after_initialize do

  # -----------------------------
  # Require our controllers & jobs
  # -----------------------------
  require_dependency File.expand_path("../app/controllers/maintenance_controller.rb", __FILE__)
  require_dependency File.expand_path("../app/jobs/scheduled/check_maintenance_plugin_update.rb", __FILE__)

  # -----------------------------
  # Routes
  # -----------------------------
  Discourse::Application.routes.append do
    get "/maintenance" => "maintenance#index"
  end

  # -----------------------------
  # Safe, Rails 8 compatible maintenance gate
  # -----------------------------
  module ::DiscourseMaintenancePlugin::MaintenanceGate
    def discourse_maintenance_check
      return unless SiteSetting.maintenance_mode_enabled
      # Always allow admins & moderators
      return if current_user && (current_user.admin? || current_user.moderator?)

      # Allow key system and auth paths while in maintenance
      allowed_prefixes = %w[
        /maintenance
        /login /logout /session
        /users /u /user_activations /password /password_resets
        /admin
        /assets /plugins /stylesheets /favicon
        /letter_avatar_proxy /letter_avatar
        /humans.txt /robots.txt /manifest /service-worker
      ]

      path = request.path
      if allowed_prefixes.any? { |p| path.start_with?(p) }
        return
      end

      # JSON/API requests: respond with 503 minimal JSON
      unless request.format.html?
        render json: {
          error: "maintenance_in_progress",
          message: SiteSetting.maintenance_mode_message
        }, status: 503
        return
      end

      # HTML requests: render our page (no Discourse layout to avoid asset deps)
      render template: "maintenance/index", layout: false, status: 503
    end
  end

  ::ApplicationController.prepend(::DiscourseMaintenancePlugin::MaintenanceGate)
end
