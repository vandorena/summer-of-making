# frozen_string_literal: true

class ViewTrackingService
  class << self
    def track_view(viewable, user_id: nil, ip_address: nil, user_agent: nil)
      # async??? oh hell yeah we fancy
      TrackViewJob.perform_later(
        viewable_type: viewable.class.name,
        viewable_id: viewable.id,
        user_id: user_id,
        ip_address: ip_address,
        user_agent: user_agent
      )
    end

    def should_count_view?(viewable, user_id: nil, ip_address: nil)
      # vibe check
      return false if user_id && viewable.respond_to?(:user_id) && viewable.user_id == user_id
      return false if recently_viewed?(viewable, user_id: user_id, ip_address: ip_address)

      true
    end

    def mark_as_viewed(viewable, user_id: nil, ip_address: nil)
      # prevent spam or view botting, they could bypass this with tor, but i cant be asked to detect that
      cache_key = build_cache_key(viewable, user_id: user_id, ip_address: ip_address)
      Rails.cache.write(cache_key, true, expires_in: 30.minutes)
    end

    def increment_view_count(viewable)
      # something atomic or some shit
      viewable.class.where(id: viewable.id).update_all("views_count = views_count + 1")
    end

    def create_view_event(viewable, user_id: nil, ip_address: nil, user_agent: nil)
      ViewEvent.create!(
        viewable: viewable,
        user_id: user_id,
        ip_address: ip_address,
        user_agent: user_agent
      )
    end

    private

    def recently_viewed?(viewable, user_id: nil, ip_address: nil)
      # dedupe
      cache_key = build_cache_key(viewable, user_id: user_id, ip_address: ip_address)
      Rails.cache.exist?(cache_key)
    end

    def build_cache_key(viewable, user_id: nil, ip_address: nil)
      identifier = user_id || ip_address
      "view_tracking:#{viewable.class.name}:#{viewable.id}:#{identifier}"
    end
  end
end
