#!/usr/bin/env ruby
# frozen_string_literal: true

ENV["RAILS_ENV"] = "som_intr_high_seas"
require_relative "../config/environment"
require "csv"
require "aws-sdk-s3"

class HighSeasDataPopulator
  def populate!
    ShipEvent.destroy_all
    Project.destroy_all
    User.destroy_all
    puts "Cleared existing data"

    users = []
    users_csv.each_with_index do |row, idx|
      puts "Processing user #{idx}" if idx % 1000 == 0

      # Parse created_at with fallback to current time
      created_at = Time.parse(row["created_at"]) rescue Time.current

      users << {
        id: idx,
        slack_id: row["slack_id"],
        email: row["email"],
        first_name: row["﻿first_name"],
        last_name: row["﻿last_name"],
        display_name: row["﻿identifier"],
        timezone: "UTC",
        avatar: "https://example.com/avatar.png",
        created_at:
      }
    end

    puts "Inserting #{users.length} users..."
    User.insert_all(users)
    puts "Successfully inserted #{User.count} users"

    projects = []
    ship_events = []
    projects_csv.each_with_index do |row, idx|
      next if row["ship_status"] == "deleted"
      next if row["duplicate_project_repo_url"] == "checked"

      u = User.find_by(display_name: row["entrant"])
      next if u.nil?

      puts "Processing project #{idx}" if idx % 1000 == 0

      # Parse created_at with fallback to current time
      created_at = Time.parse(row["created_at"]) rescue Time.current
      hours = row["hours"]

      # High Seas' ship chain system was - and hindsight is 20:20 - foolishly built as a linked list.
      # `Ship`s had a `reshipped_(to|from)` field that would link to other `Ship`s.
      # Data was denormalised across every `Ship` and source of truthiness was ambiguous and often erroneous.
      # To construct the Summer of Making structure (one `Project` has_many `ShipEvent`s), we must traverse the HS linked list;
      if row["reshipped_from"].to_s.strip.empty? # Is this a root `Ship`?
        projects << {
          id: idx,
          title: row["title"],
          description: row["﻿identifier"],
          repo_link: row["repo_link"],
          readme_link: row["readme_link"],
          demo_link: row["deploy_link"],
          user_id: u.id,
          created_at:
        }
      else
        root_ship_id = nil
        curr_ident = row["﻿identifier"]
        corrupted_chain = false

        while root_ship_id.nil? && !corrupted_chain
          found_index = projects_csv.find_index { |p| p["reshipped_to"] == curr_ident }

          if found_index.nil?
            puts "Corrupted ship chain detected for #{row["﻿identifier"]}, skipping..."
            corrupted_chain = true
            break
          end

          found = projects_csv[found_index]

          begin
            root_ship_id = found_index if found["reshipped_from"].to_s.strip.empty?
          rescue => e
            puts "Error processing ship chain: #{e}"
            corrupted_chain = true
            break
          end

          curr_ident = found["﻿identifier"]
        end

        next if corrupted_chain

        puts "okay. found root_ship_id (#{root_ship_id}) for rowident #{row["﻿identifier"]}"

        ship_events << {
          id: idx,
          project_id: root_ship_id,
          created_at:
        }
      end
    end

    puts "Inserting #{projects.length} projects..."
    Project.insert_all(projects)
    puts "Successfully inserted #{Project.count} projects"
  end

  private

  def users_csv
    @users_csv ||= get_csv "people-Everything.csv"
  end

  def votes_csv
    @votes_csv ||= get_csv "battles-Everything.csv"
  end

  def projects_csv
    @projects_csv ||= get_csv "ships-Everything.csv"
  end

  def get_csv(path)
    bucket = "hackclub-high-seas-airtable-exports"
    local_path = "/tmp/#{path}"

    unless File.exist?(local_path)
      puts "Fetching #{path}"
      response = client.get_object(bucket:, key: path)
      File.write(local_path, response.body.read)
      puts "Fetched #{path}"
    else
      puts "File #{path} alr exists in /tmp"
    end

    csv_text = File.read(local_path)
    CSV.parse(csv_text, headers: true)
  end

  def client
    @client ||= Aws::S3::Client.new(
      access_key_id: Rails.application.credentials.cloudflare_high_seas_integration_data.access_key_id,
      secret_access_key: Rails.application.credentials.cloudflare_high_seas_integration_data.secret_access_key,
      region: "auto",
      endpoint: Rails.application.credentials.cloudflare_high_seas_integration_data.url
    )
  end
end

# Run the populator
HighSeasDataPopulator.new.populate!
