# frozen_string_literal: true

class TrackViewJob < ApplicationJob
  queue_as :default

  def perform(viewable_type:, viewable_id:, user_id: nil, ip_address: nil)
    viewable = viewable_type.constantize.find_by(id: viewable_id)
    return unless viewable

    # first check, because caching is a bitch
    return unless ViewTrackingService.should_count_view?(viewable, user_id: user_id, ip_address: ip_address)

    # dedupe shit
    ViewTrackingService.mark_as_viewed(viewable, user_id: user_id, ip_address: ip_address)

    ViewTrackingService.increment_view_count(viewable)
  rescue ActiveRecord::RecordNotFound
    Honeybadger.notify("cant find #{viewable_type} with id #{viewable_id} for views")
  rescue StandardError => e
    Honeybadger.notify(e, context: { viewable_type: viewable_type, viewable_id: viewable_id, user_id: user_id, ip_address: ip_address })
  end
end
