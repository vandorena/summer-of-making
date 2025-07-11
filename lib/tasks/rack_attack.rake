# frozen_string_literal: true

namespace :rack_attack do
  desc "Show current Rack Attack cache statistics"
  task stats: :environment do
    begin
      if Rails.env.production? && Rails.cache.is_a?(ActiveSupport::Cache::SolidCacheStore)
        # Query the solid_cache_entries table for Rack Attack keys
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

        puts "Rack Attack Cache Statistics (Solid Cache):"
        puts "============================================="
        puts "Total keys: #{cache_entries["total_count"] || cache_entries["count"] || 0}"
        puts "Rate limited IPs: #{throttle_entries["count"] || 0}"
        puts "Login throttled IPs: #{login_entries["count"] || 0}"
        puts "API throttled IPs: #{api_entries["count"] || 0}"

        # Show active throttles with details
        active_throttles = ActiveRecord::Base.connection.execute(
          "SELECT key, expires_at FROM solid_cache_entries WHERE key LIKE 'rack::attack:%' AND expires_at > NOW() LIMIT 10"
        )

        if active_throttles.any?
          puts "\nActive throttles (showing first 10):"
          active_throttles.each do |entry|
            puts "  #{entry["key"]}: expires at #{entry["expires_at"]}"
          end
        end
      else
        puts "Rack Attack Cache Statistics (#{Rails.cache.class.name}):"
        puts "=========================================="
        puts "Cache store: #{Rails.cache.class.name}"
        puts "Memory store statistics are not available for inspection."
        puts "Rack Attack is working but throttle details can't be shown."
      end
    rescue => e
      puts "Error retrieving stats: #{e.message}"
    end
  end

  desc "Clear all Rack Attack cache"
  task clear_cache: :environment do
    begin
      if Rails.env.production? && Rails.cache.is_a?(ActiveSupport::Cache::SolidCacheStore)
        # Delete all Rack Attack entries from solid_cache_entries
        result = ActiveRecord::Base.connection.execute(
          "DELETE FROM solid_cache_entries WHERE key LIKE 'rack::attack:%'"
        )

        cleared_count = result.cmd_tuples rescue result.to_a.size rescue 0

        if cleared_count > 0
          puts "Cleared #{cleared_count} Rack Attack cache entries from Solid Cache"
        else
          puts "No Rack Attack cache entries found in Solid Cache"
        end
      else
        # For memory store or other cache stores
        Rails.cache.clear
        puts "Cleared all cache entries (#{Rails.cache.class.name})"
      end
    rescue => e
      puts "Error clearing cache: #{e.message}"
    end
  end

  desc "Unblock an IP address"
  task :unblock_ip, [ :ip ] => :environment do |task, args|
    ip = args[:ip]
    if ip.blank?
      puts "Usage: rake rack_attack:unblock_ip[192.168.1.1]"
      exit 1
    end

    begin
      if Rails.env.production? && Rails.cache.is_a?(ActiveSupport::Cache::SolidCacheStore)
        # Remove IP from various throttle keys in solid_cache_entries
        throttle_names = [
          "requests by IP",
          "requests by IP per minute",
          "login attempts by IP",
          "api requests by IP"
        ]

        removed_keys = 0
        throttle_names.each do |throttle_name|
          key = "rack::attack:#{throttle_name}:#{ip}"
          result = ActiveRecord::Base.connection.execute(
            "DELETE FROM solid_cache_entries WHERE key = $1",
            [ key ]
          )

          deleted_count = result.cmd_tuples rescue result.to_a.size rescue 0
          if deleted_count > 0
            removed_keys += 1
            puts "Removed: #{key}"
          end
        end

        if removed_keys > 0
          puts "Successfully unblocked IP #{ip} (removed #{removed_keys} keys from Solid Cache)"
        else
          puts "No active throttles found for IP #{ip} in Solid Cache"
        end
      else
        # For memory store, use Rails cache delete
        throttle_names = [
          "requests by IP",
          "requests by IP per minute",
          "login attempts by IP",
          "api requests by IP"
        ]

        removed_keys = 0
        throttle_names.each do |throttle_name|
          key = "rack::attack:#{throttle_name}:#{ip}"
          if Rails.cache.delete(key)
            removed_keys += 1
            puts "Removed: #{key}"
          end
        end

        if removed_keys > 0
          puts "Successfully unblocked IP #{ip} (removed #{removed_keys} keys from #{Rails.cache.class.name})"
        else
          puts "No active throttles found for IP #{ip} in #{Rails.cache.class.name}"
        end
      end
    rescue => e
      puts "Error unblocking IP: #{e.message}"
    end
  end

  desc "Monitor Rack Attack activity in real-time"
  task monitor: :environment do
    puts "Monitoring Rack Attack activity... (Press Ctrl+C to stop)"

    # Subscribe to Rack Attack notifications
    ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
      req = payload[:request]
      timestamp = Time.current.strftime("%Y-%m-%d %H:%M:%S")

      case req.env["rack.attack.match_type"]
      when :throttle
        puts "[#{timestamp}] THROTTLED: #{req.env['rack.attack.matched']} #{req.ip} #{req.request_method} #{req.fullpath}"
      when :blocklist
        puts "[#{timestamp}] BLOCKED: #{req.env['rack.attack.matched']} #{req.ip} #{req.request_method} #{req.fullpath} User-Agent: #{req.user_agent}"
      when :safelist
        puts "[#{timestamp}] SAFELISTED: #{req.env['rack.attack.matched']} #{req.ip} #{req.request_method} #{req.fullpath}"
      end
    end

    # Keep the task running
    loop do
      sleep 1
    end
  end
end
