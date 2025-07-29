class OneTime::MigrateNeighborhoodDataJob < ApplicationJob
  queue_as :default

  def perform(dry_run = true)
    ActiveRecord::Base.transaction do
      pull_data

      raise ActiveRecord::Rollback if dry_run
    end
  end

  private

  def pull_data
    transfers = cache_with_json("transfers_all.json") do
      cached_records_from("Post Event - Hour Transfers").map { |r| r&.fields }
    end
    transfers_for_som = cache_with_json("transfers_for_som.json") do
      transfers.select { |r| r["Which transfer option would you like to go with?"] == "Summer of Making" }
    end
    puts "found #{transfers_for_som.count} hour transfers"
    slack_ids_for_som = transfers_for_som.map { |r| r["What is your Slack ID?"] }.compact.uniq

    filter_for_neighbors = slack_ids_for_som.map { |slack_id| "{Slack ID (from slackNeighbor)}='#{slack_id}'" }
    neighbors = cache_with_json("neighbors.json") do
      cached_records_from("neighbors", filter: "OR(#{filter_for_neighbors.join(", ")})").map { |r| r&.fields }
    end
    puts "found #{neighbors.count} neighbors"

    filter_for_projects = slack_ids_for_som.map { |slack_id| "{Slack ID (from slackNeighbor) (from neighbors)}='#{slack_id}'" }
    projects = cache_with_json("projects.json") do
      cached_records_from("YSWS Project Submission", filter: "OR(#{filter_for_projects.join(", ")})").map { |r| r&.fields }
    end
    puts "found #{projects.count} projects"

    # these are like devlogs
    filter_for_posts = slack_ids_for_som.map { |slack_id| "{slackId}='#{slack_id}'" }
    posts = cache_with_json("posts.json") do
      cached_records_from("Posts", filter: "OR(#{filter_for_posts.join(", ")})").map { |r| r&.fields }
    end
    puts "found #{posts.count} posts"
  end

  def cache_with_json(cache_name, &block)
    unless File.exist?(cache_name)
      results = block.call
      export_to_json(results, cache_name)
    end
    JSON.parse(File.read(cache_name))
  end

  def export_to_json(records, filename)
    File.open(filename, "w") do |file|
      file.write(JSON.pretty_generate(records))
    end
  end

  def table(table_name)
    Norairrecord.table(
      ENV["NEIGHBORHOOD_AIRTABLE_KEY"],
      "appnsN4MzbnfMY0ai",
      table_name
    )
  end

  def cached_records_from(table_name, filter: nil)
    # jk, no caching for now
    table(table_name).all(filter: filter)
  end
end
