# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module ::Jobs
  class CheckMaintenancePluginUpdate < ::Jobs::Scheduled
    every 1.day

    def execute(_args)
      repo = SiteSetting.maintenance_update_repo.presence
      return if repo.blank?

      url = URI("https://api.github.com/repos/#{repo}/releases/latest")
      latest = nil

      begin
        res = Net::HTTP.start(url.host, url.port, use_ssl: true, open_timeout: 3, read_timeout: 5) do |http|
          req = Net::HTTP::Get.new(url)
          req["User-Agent"] = "Discourse/#{Discourse::VERSION::STRING} (maintenance-plugin)"
          http.request(req)
        end
        if res.is_a?(Net::HTTPSuccess)
          data = JSON.parse(res.body) rescue {}
          latest = data["tag_name"].to_s.sub(/^v/i, "")
        end
      rescue => e
        Rails.logger.warn("[#{::DiscourseMaintenancePlugin::PLUGIN_NAME}] update check failed: #{e.class}: #{e.message}")
        return
      end

      return if latest.blank?

      current = ::DiscourseMaintenancePlugin::PLUGIN_VERSION
      return unless Gem::Version.correct?(current) && Gem::Version.correct?(latest)
      return unless Gem::Version.new(latest) > Gem::Version.new(current)

      # de-dupe: only notify once per version
      last = PluginStore.get(::DiscourseMaintenancePlugin::PLUGIN_NAME, ::DiscourseMaintenancePlugin::UPDATE_STORE_KEY)
      return if last == latest

      if defined?(::AdminNotification)
        ::AdminNotification.create!(
          notification_type: ::AdminNotification.types[:custom],
          topic_title: "Maintenance plugin update available",
          message: "A new version (#{latest}) of #{::DiscourseMaintenancePlugin::PLUGIN_NAME} is available on GitHub. Current: #{current}."
        )
      end

      PluginStore.set(::DiscourseMaintenancePlugin::PLUGIN_NAME, ::DiscourseMaintenancePlugin::UPDATE_STORE_KEY, latest)
    end
  end
end
