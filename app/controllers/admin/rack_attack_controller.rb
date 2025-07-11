module Admin
  class RackAttackController < ApplicationController
    def index
      @cache_stats = get_cache_stats
      @recent_blocks = get_recent_activity("rack_attack_blocks")
      @recent_throttles = get_recent_activity("rack_attack_throttles")
    end

    def clear_cache
      cache_store = Rack::Attack.cache.store
      if cache_store.respond_to?(:clear)
        cache_store.clear
        flash[:success] = "purged that johnson"
      elsif Rails.env.production? && cache_store.is_a?(ActiveSupport::Cache::SolidCacheStore)
        Rails.cache.delete_matched("rack::attack:*")
        flash[:success] = "purged that johnson"
      else
        Rails.cache.clear
        flash[:success] = "purged that johnson"
      end
      redirect_to admin_rack_attack_index_path
    rescue => e
      flash[:error] = "fucky wucky #{e.message}"
      redirect_to admin_rack_attack_index_path
    end

    def unblock_ip
      ip = params[:ip]
      if ip.present?
        cache_store = Rack::Attack.cache.store

        %w[
          requests\ by\ IP
          requests\ by\ IP\ per\ minute
          login\ attempts\ by\ IP
          api\ requests\ by\ IP
        ].each do |throttle_name|
          key = "rack::attack:#{throttle_name}:#{ip}"
          cache_store.delete(key)
        end

        flash[:success] = "IP #{ip} unblocked"
      else
        flash[:error] = "wuh"
      end
      redirect_to admin_rack_attack_index_path
    end

    private

    def get_cache_stats
      begin
        if Rails.env.production? && Rails.cache.is_a?(ActiveSupport::Cache::SolidCacheStore)
          cache_entries = ActiveRecord::Base.connection.execute(
            "SELECT COUNT(*) as total_count FROM solid_cache_entries WHERE key LIKE 'rack::attack:%'"
          ).first

          throttle_entries = ActiveRecord::Base.connection.execute(
            "SELECT COUNT(*) as count FROM solid_cache_entries WHERE key LIKE 'rack::attack:%requests by IP%'"
          ).first

          login_entries = ActiveRecord::Base.connection.execute(
            "SELECT COUNT(*) as count FROM solid_cache_entries WHERE key LIKE 'rack::attack:%login attempts%'"
          ).first

          api_entries = ActiveRecord::Base.connection.execute(
            "SELECT COUNT(*) as count FROM solid_cache_entries WHERE key LIKE 'rack::attack:%api requests%'"
          ).first

          {
            total_keys: cache_entries["total_count"] || cache_entries["count"] || 0,
            throttle_keys: throttle_entries["count"] || 0,
            login_throttle_keys: login_entries["count"] || 0,
            api_throttle_keys: api_entries["count"] || 0
          }
        else
          {
            total_keys: "N/A (Memory Store)",
            throttle_keys: "N/A (Memory Store)",
            login_throttle_keys: "N/A (Memory Store)",
            api_throttle_keys: "N/A (Memory Store)"
          }
        end
      rescue => e
        Rails.logger.error "fucky wucky #{e.message}"
        { error: e.message }
      end
    end

    def get_recent_activity(log_key)
      # to make this work, we dont have a log drain i think so we are kinda cooked here
      []
    end
  end
end
