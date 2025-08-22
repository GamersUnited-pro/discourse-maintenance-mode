# frozen_string_literal: true

# name: discourse-maintenance-mode
# about: Toggleable maintenance mode with stylish page + admin-only update notifications
# version: 1.0.25
# authors: GamersUnited.pro
# url: https://github.com/GamersUnited-pro/discourse-maintenance-plugin

enabled_site_setting :maintenance_mode_enabled

module ::DiscourseMaintenancePlugin
  PLUGIN_NAME = "discourse-maintenance-plugin"
  PLUGIN_VERSION = "1.0.25"
  UPDATE_STORE_KEY = "last_notified_version"
end

after_initialize do
  require_dependency File.expand_path("app/controllers/maintenance_controller.rb", __dir__)
  require_dependency File.expand_path("app/jobs/scheduled/check_maintenance_plugin_update.rb", __dir__)

  # Make plugin views available globally
  ApplicationController.append_view_path File.expand_path("app/views", __dir__)

  # Register JS for auto-refresh (CSP safe)
  register_asset "javascripts/maintenance-refresh.js"

  Discourse::Application.routes.append do
    get "/maintenance" => "maintenance#index"
  end

  module ::DiscourseMaintenancePlugin::MaintenanceGate
    def discourse_maintenance_check
      return unless SiteSetting.maintenance_mode_enabled
      return if current_user&.admin? || current_user&.moderator?

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
      return if allowed_prefixes.any? { |p| path.start_with?(p) }

      # Set instance variables for maintenance page
      @title = SiteSetting.maintenance_mode_title.presence || "We'll be back soon"
      @message = SiteSetting.maintenance_mode_message.presence || "The forum is currently under maintenance. Please check back later."
      @interval = (SiteSetting.maintenance_refresh_interval || 15).to_i

      if request.format.html?
        render "maintenance/index", layout: false, formats: [:html], status: 503
      else
        # For API/JSON calls, redirect to maintenance page
        redirect_to "/maintenance" and return
      end
    end
  end

  ::ApplicationController.prepend(::DiscourseMaintenancePlugin::MaintenanceGate)
  ::ApplicationController.before_action :discourse_maintenance_check

  register_admin_page_link "discourse-maintenance-mode" do
    render partial: "admin/plugins/discourse-maintenance-mode/update_notice"
  end
end
