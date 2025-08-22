# frozen_string_literal: true

module ::DiscourseMaintenancePlugin
  class AdminController < ::Admin::AdminController
    requires_plugin DiscourseMaintenancePlugin::PLUGIN_NAME

    def version
      render json: {
        current_version: DiscourseMaintenancePlugin::PLUGIN_VERSION,
        latest_version: PluginStore.get(DiscourseMaintenancePlugin::PLUGIN_NAME, DiscourseMaintenancePlugin::UPDATE_STORE_KEY)
      }
    end
  end
end
