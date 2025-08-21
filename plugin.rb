# frozen_string_literal: true

# name: discourse-maintenance-mode
# about: Toggleable maintenance mode with stylish page + admin-only update notifications
# version: 1.0.10
# authors: GamersUnited.pro
# url: https://github.com/GamersUnited-pro/discourse-maintenance-plugin

enabled_site_setting :maintenance_mode_enabled

# -----------------------------
# Plugin constants (top-level for jobs)
# -----------------------------
module ::DiscourseMaintenancePlugin
  PLUGIN_NAME = "discourse-maintenance-plugin"
  PLUGIN_VERSION = "1.0.10"
  UPDATE_STORE_KEY = "last_notified_version"
end

after_initialize do
  # Require controllers & jobs
  require_dependency File.expand_path("app/controllers/maintenance_controller.rb", __dir__)
  require_dependency File.expand_path("app/jobs/scheduled/check_maintenance_plugin_update.rb", __dir__)

  # Routes
  Discourse::Application.routes.append do
    get "/maintenance" => "discourse_maintenance_plugin/maintenance#index"
  end

  # Maintenance check patch
  ApplicationController.class_eval do
    before_action :discourse_maintenance_check

    private

    def discourse_maintenance_check
      return unless SiteSetting.maintenance_mode_enabled
      return if current_user&.admin? || current_user&.moderator?

      allowed_prefixes = %w[
        /maintenance /login /logout /session /users /u /user_activations /password /password_resets
        /admin /assets /plugins /stylesheets /favicon
        /letter_avatar_proxy /letter_avatar /humans.txt /robots.txt /manifest /service-worker
      ]

      path = request.path
      return if allowed_prefixes.any? { |p| path.start_with?(p) }

      unless request.format.html?
        render json: {
          error: "maintenance_in_progress",
          message: SiteSetting.maintenance_mode_message
        }, status: 503
        return
      end

      render template: "maintenance/index", layout: false, status: 503
    end
  end
end
