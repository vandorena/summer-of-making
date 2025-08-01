namespace :debug do
  desc "Debug a single devlog's Hackatime calculation in detail"
  task :single_devlog, [ :devlog_id ] => :environment do |t, args|
    devlog_id = args[:devlog_id] || ENV["DEVLOG_ID"]

    if devlog_id.blank?
      puts "Usage: rake debug:single_devlog[DEVLOG_ID]"
      puts "   or: DEVLOG_ID=123 rake debug:single_devlog"
      exit 1
    end

    devlog = Devlog.find(devlog_id)
    puts "=" * 80
    puts "DEBUGGING DEVLOG #{devlog.id}"
    puts "=" * 80

    puts "Basic Info:"
    puts "  User: #{devlog.user.email} (slack_id: #{devlog.user.slack_id}) (id: #{devlog.user.id})"
    puts "  Project: #{devlog.project.title}"
    puts "  Created: #{devlog.created_at}"
    puts "  Current duration: #{devlog.duration_seconds} seconds"
    puts "  Hackatime projects: #{devlog.hackatime_projects_key_snapshot}"
    puts "  User has_hackatime: #{devlog.user.has_hackatime}"
    puts "  Last pulled: #{devlog.hackatime_pulled_at}"

    if devlog.hackatime_projects_key_snapshot.blank?
      puts "\n❌ NO HACKATIME PROJECTS CONFIGURED - This explains why it's 0"
      exit 0
    end

    puts "\nTime Range Calculation:"
    prev_time = Devlog.where(project_id: devlog.project_id)
                      .where("created_at < ?", devlog.created_at)
                      .order(created_at: :desc)
                      .first&.created_at

    prev_time ||= Time.use_zone("America/New_York") { Time.parse("2025-06-16").beginning_of_day }.utc

    puts "  Previous devlog time: #{prev_time}"
    puts "  Current devlog time: #{devlog.created_at.utc}"
    puts "  Time window: #{((devlog.created_at.utc - prev_time) / 3600).round(2)} hours"

    # Build API URL
    project_keys = devlog.hackatime_projects_key_snapshot.join(",")
    encoded_project_keys = URI.encode_www_form_component(project_keys)
    url = "https://hackatime.hackclub.com/api/v1/users/#{devlog.user.slack_id}/stats?filter_by_project=#{encoded_project_keys}&start_date=#{prev_time.iso8601}&end_date=#{devlog.created_at.utc.iso8601}&features=projects&test_param=true"

    puts "\nAPI Call Details:"
    puts "  Project keys: #{project_keys}"
    puts "  Encoded keys: #{encoded_project_keys}"
    puts "  URL: #{url}"

    # Make the actual API call
    puts "\nMaking API Call..."
    headers = { "RACK_ATTACK_BYPASS" => ENV["HACKATIME_BYPASS_KEYS"] }.compact
    puts "  Headers: #{headers}"

    begin
      response = Faraday.get(url, nil, headers)
      puts "  Response Status: #{response.status}"
      puts "  Response Headers: #{response.headers.to_h.slice('content-type', 'x-ratelimit-remaining', 'x-ratelimit-limit')}"

      if response.success?
        begin
          data = JSON.parse(response.body)
          puts "\nAPI Response Data:"
          puts "  Status: #{data.dig('data', 'status')}"
          puts "  Total seconds: #{data.dig('data', 'total_seconds')}"
          puts "  Unique total seconds: #{data.dig('data', 'unique_total_seconds')}"
          puts "  Projects count: #{data.dig('data', 'projects')&.length || 0}"

          if data.dig("data", "projects")&.any?
            puts "\nProject breakdown:"
            data.dig("data", "projects").each do |project|
              puts "    #{project['name']}: #{project['total_seconds']}s"
            end
          else
            puts "\n❌ NO PROJECTS IN RESPONSE - This is why it's 0!"
            puts "   Possible reasons:"
            puts "   - Project keys don't match Hackatime project names"
            puts "   - No coding activity in this time window"
            puts "   - User's Hackatime data doesn't include these projects"
          end

          # Show what the method would return
          result_seconds = data.dig("data", "unique_total_seconds") || data.dig("data", "total_seconds") || 0
          puts "\nWould return: #{result_seconds} seconds"

        rescue JSON::ParserError => e
          puts "❌ JSON Parse Error: #{e.message}"
          puts "Raw response body: #{response.body}"
        end
      else
        puts "❌ API Error: #{response.status}"
        puts "Response body: #{response.body}"
      end

    rescue => e
      puts "❌ Request Error: #{e.class.name} - #{e.message}"
    end

    # Test without time filters to see if user has ANY data
    puts "\n" + "=" * 50
    puts "TESTING USER'S OVERALL HACKATIME DATA"
    puts "=" * 50

    general_url = "https://hackatime.hackclub.com/api/v1/users/#{devlog.user.slack_id}/stats?features=projects&test_param=true"
    puts "General stats URL: #{general_url}"

    begin
      general_response = Faraday.get(general_url, nil, headers)
      if general_response.success?
        general_data = JSON.parse(general_response.body)
        puts "User's total coding time: #{general_data.dig('data', 'total_seconds')} seconds"
        puts "User's project count: #{general_data.dig('data', 'projects')&.length || 0}"

        if general_data.dig("data", "projects")&.any?
          puts "\nUser's projects in Hackatime:"
          general_data.dig("data", "projects").first(10).each do |project|
            puts "  - #{project['name']}: #{project['total_seconds']}s"
          end

          # Check if any project keys match
          hackatime_project_names = general_data.dig("data", "projects").map { |p| p["name"] }
          devlog_project_keys = devlog.hackatime_projects_key_snapshot
          matches = hackatime_project_names & devlog_project_keys

          puts "\nProject key matching:"
          puts "  Devlog project keys: #{devlog_project_keys}"
          puts "  Hackatime project names: #{hackatime_project_names.first(10)}"
          puts "  Matches: #{matches}"

          if matches.empty?
            puts "\n❌ NO PROJECT KEY MATCHES - This is likely the problem!"
            puts "   The project keys in the devlog don't match any Hackatime project names"
          end
        else
          puts "\n❌ USER HAS NO PROJECTS IN HACKATIME"
        end
      else
        puts "❌ Failed to get general stats: #{general_response.status}"
      end
    rescue => e
      puts "❌ Error getting general stats: #{e.message}"
    end
  end
end
