# frozen_string_literal: true

# name: discourse-maintenance-mode
# about: Toggleable maintenance mode with stylish page + admin-only update notifications
# version: 1.0.11
# authors: GamersUnited.pro
# url: https://github.com/GamersUnited-pro/discourse-maintenance-plugin

enabled_site_setting :maintenance_mode_enabled

after_initialize do
  module ::DiscourseMaintenancePlugin
    PLUGIN_NAME = "discourse-maintenance-plugin"
    PLUGIN_VERSION = "1.0.11"
    UPDATE_STORE_KEY = "last_notified_version"
  end

  require_dependency File.expand_path("../app/controllers/maintenance_controller.rb", __FILE__)
  require_dependency File.expand_path("../app/jobs/scheduled/check_maintenance_plugin_update.rb", __FILE__)

  Discourse::Application.routes.append do
    get "/maintenance" => "maintenance#index"
  end

  reloadable_patch do
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

        if request.format.html?
          render template: "maintenance/index", layout: false, status: 503
        else
          # allow JSON/API internally; do not block
          return
        end
      end
    end
  end
end
