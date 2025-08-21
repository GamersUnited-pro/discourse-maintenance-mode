# frozen_string_literal: true

class ::MaintenanceController < ::ApplicationController
  skip_before_action :check_xhr
  layout false

  def index
    unless SiteSetting.maintenance_mode_enabled
      redirect_to "/" and return
    end

    @title = SiteSetting.maintenance_mode_title.presence || "We'll be back soon"
    @message = SiteSetting.maintenance_mode_message.presence || "The forum is currently under maintenance. Please check back later."
    @interval = (SiteSetting.maintenance_refresh_interval || 15).to_i
  end
end
