# frozen_string_literal: true

module ViewTrackable
  extend ActiveSupport::Concern

  private

  def track_view(viewable)
    return unless viewable

    ViewTrackingService.track_view(
      viewable,
      user_id: current_user&.id,
      ip_address: request.remote_ip
    )
  end
end
