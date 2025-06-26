class OneTime::ProcessPayoutCsvJob < ApplicationJob
  queue_as :default

  def perform(csv_source, source_type = :file)
    require "csv"
    require "net/http"
    require "uri"

    # Fetch CSV data based on source type
    csv_data = fetch_csv_data(csv_source, source_type)

    # Parse CSV data
    csv_rows = CSV.parse(csv_data, headers: true)

    Rails.logger.info "Processing #{csv_rows.count} payout records from #{source_type} source"

    # Validate all data before processing
    validation_errors = validate_csv_data(csv_rows)

    if validation_errors.any?
      Rails.logger.error "Validation failed. Aborting payout processing:"
      validation_errors.each { |error| Rails.logger.error "  #{error}" }
      raise StandardError, "CSV validation failed: #{validation_errors.join(', ')}"
    end

    # Process all payouts in a single transaction
    processed_count = 0

    ActiveRecord::Base.transaction do
      csv_rows.each_with_index do |row, index|
        slack_id = row["slack_id"]&.strip
        amount_str = row["amount"]&.strip
        reason = row["reason"]&.strip || "Manual payout from CSV"

        # Parse amount (already validated above)
        amount = BigDecimal(amount_str)

        # Find user by Slack ID (already validated above)
        user = User.find_by(slack_id: slack_id)

        # Create payout
        payout = Payout.create!(
          user: user,
          amount: amount,
          reason: reason
        )

        processed_count += 1
        Rails.logger.info "Created payout: $#{amount} for user #{user.display_name} (#{slack_id}) - Reason: #{reason}"
      end
    end

    Rails.logger.info "Payout processing completed successfully: #{processed_count} payouts created"

    # Return results for potential use by caller
    {
      processed_count: processed_count,
      error_count: 0,
      errors: []
    }

  rescue StandardError => e
    Rails.logger.error "Payout processing failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def fetch_csv_data(source, source_type)
    case source_type.to_sym
    when :file
      unless File.exist?(source)
        raise StandardError, "CSV file not found: #{source}"
      end
      File.read(source)

    when :url
      uri = URI.parse(source)
      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        raise StandardError, "Failed to fetch CSV from URL: #{response.code} #{response.message}"
      end

      response.body

    when :data
      # Assume source is already CSV data
      source

    else
      raise StandardError, "Invalid source type: #{source_type}. Must be :file, :url, or :data"
    end
  end

  def validate_csv_data(csv_rows)
    errors = []

    csv_rows.each_with_index do |row, index|
      slack_id = row["slack_id"]&.strip
      amount_str = row["amount"]&.strip

      # Skip empty rows
      next if slack_id.blank? && amount_str.blank?

      # Check for required fields
      if slack_id.blank?
        errors << "Row #{index + 2}: Missing slack_id"
        next
      end

      if amount_str.blank?
        errors << "Row #{index + 2}: Missing amount for Slack ID '#{slack_id}'"
        next
      end

      # Validate amount format
      begin
        amount = BigDecimal(amount_str)
        if amount <= 0
          errors << "Row #{index + 2}: Amount must be positive for Slack ID '#{slack_id}'"
        end
      rescue ArgumentError
        errors << "Row #{index + 2}: Invalid amount format '#{amount_str}' for Slack ID '#{slack_id}'"
        next
      end

      # Validate user exists
      user = User.find_by(slack_id: slack_id)
      if user.nil?
        errors << "Row #{index + 2}: User not found with Slack ID '#{slack_id}'"
      end
    end

    errors
  end
end
