class OneTime::ProcessPayoutCsvJob < ApplicationJob
  queue_as :default

  def perform(csv_source, force_proceed = false)
    require "csv"
    require "net/http"
    require "uri"

    # Auto-detect source type
    source_type = detect_source_type(csv_source)

    # Fetch CSV data based on source type
    csv_data = fetch_csv_data(csv_source, source_type)

    # Parse CSV data
    csv_rows = CSV.parse(csv_data, headers: true)

    Rails.logger.info "Processing #{csv_rows.count} payout records from #{source_type} source"

    # Phase 1: Validate and identify issues
    validation_result = validate_csv_data(csv_rows)

    if validation_result[:critical_errors].any?
      Rails.logger.error "Critical validation errors found. Aborting payout processing:"
      validation_result[:critical_errors].each { |error| Rails.logger.error "  #{error}" }
      raise StandardError, "CSV validation failed: #{validation_result[:critical_errors].join(', ')}"
    end

    # Check for missing users
    if validation_result[:missing_users].any? && !force_proceed
      missing_users_message = generate_missing_users_message(validation_result[:missing_users])
      Rails.logger.warn "MISSING USERS DETECTED:"
      Rails.logger.warn missing_users_message
      Rails.logger.warn "To proceed with only valid users, run with force_proceed: true"
      raise StandardError, "Missing users detected. Set force_proceed: true to continue with valid users only."
    end

    # Phase 2: Process only valid users
    valid_rows = validation_result[:valid_rows]

    if valid_rows.empty?
      Rails.logger.warn "No valid rows to process"
      return { processed_count: 0, error_count: 0, errors: [], missing_users: validation_result[:missing_users] }
    end

    Rails.logger.info "Proceeding with #{valid_rows.count} valid users"

    # Process all payouts in a single transaction
    processed_count = 0

    ActiveRecord::Base.transaction do
      valid_rows.each do |row_data|
        slack_id = row_data[:slack_id]
        amount = row_data[:amount]
        reason = row_data[:reason]
        user = row_data[:user]

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
      errors: [],
      missing_users: validation_result[:missing_users],
      skipped_count: validation_result[:missing_users].count
    }

  rescue StandardError => e
    Rails.logger.error "Payout processing failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def detect_source_type(source)
    return :data if source.is_a?(String) && source.include?("\n") && source.include?(",")
    return :url if source.is_a?(String) && (source.start_with?("http://", "https://") || source.match?(/^https?:\/\//))
    return :file if source.is_a?(String) && File.exist?(source)
    :data # Default to treating as raw CSV data
  end

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
    critical_errors = []
    missing_users = []
    valid_rows = []

    csv_rows.each_with_index do |row, index|
      slack_id = row["slack_id"]&.strip
      amount_str = row["amount"]&.strip

      # Skip empty rows
      next if slack_id.blank? && amount_str.blank?

      # Check for required fields
      if slack_id.blank?
        critical_errors << "Row #{index + 2}: Missing slack_id"
        next
      end

      if amount_str.blank?
        critical_errors << "Row #{index + 2}: Missing amount for Slack ID '#{slack_id}'"
        next
      end

      # Validate amount format
      begin
        # Handle both integer and decimal amounts
        amount = parse_amount(amount_str)
        if amount <= 0
          critical_errors << "Row #{index + 2}: Amount must be positive for Slack ID '#{slack_id}'"
          next
        end
      rescue ArgumentError, TypeError => e
        critical_errors << "Row #{index + 2}: Invalid amount format '#{amount_str}' for Slack ID '#{slack_id}': #{e.message}"
        next
      end

      # Validate user exists
      user = User.find_by(slack_id: slack_id)
      if user.nil?
        missing_users << { slack_id: slack_id, amount: amount, reason: row["reason"]&.strip || "Manual payout from CSV" }
      else
        valid_rows << {
          slack_id: slack_id,
          amount: amount,
          reason: row["reason"]&.strip || "Manual payout from CSV",
          user: user
        }
      end
    end

    {
      critical_errors: critical_errors,
      missing_users: missing_users,
      valid_rows: valid_rows
    }
  end

  def generate_missing_users_message(missing_users)
    message = "The following users were not found in the database:\n"
    missing_users.each do |missing|
      message += "  - Slack ID: #{missing[:slack_id]}, Amount: $#{missing[:amount]}, Reason: #{missing[:reason]}\n"
    end
    message += "\nTotal missing users: #{missing_users.count}"
    message += "\nTotal amount for missing users: $#{missing_users.sum { |u| u[:amount] }}"
    message
  end

  def parse_amount(amount_str)
    return nil if amount_str.nil? || amount_str.strip.empty?

    # Remove any currency symbols and whitespace
    cleaned_amount = amount_str.strip.gsub(/[$,\s]/, "")

    # Handle both integer and decimal formats
    if cleaned_amount.match?(/^\d+$/)
      # Integer format (e.g., "100")
      BigDecimal(cleaned_amount)
    elsif cleaned_amount.match?(/^\d+\.\d+$/)
      # Decimal format (e.g., "100.50")
      BigDecimal(cleaned_amount)
    elsif cleaned_amount.match?(/^\d+\.$/)
      # Decimal with no cents (e.g., "100.")
      BigDecimal(cleaned_amount + "0")
    else
      raise ArgumentError, "Invalid amount format: #{amount_str}"
    end
  end
end
