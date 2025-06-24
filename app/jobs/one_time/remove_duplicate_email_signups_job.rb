class OneTime::RemoveDuplicateEmailSignupsJob < ApplicationJob
  queue_as :default

  def perform
    duplicates_sql = <<~SQL
      SELECT email, array_agg(id ORDER BY created_at ASC) as ids
      FROM email_signups
      GROUP BY email
      HAVING count(*) > 1
    SQL

    Rails.logger.info "Starting removal of duplicate email signups"

    duplicate_groups = ActiveRecord::Base.connection.execute(duplicates_sql)
    total_removed = 0

    duplicate_groups.each do |group|
      email = group["email"]
      ids = group["ids"].gsub(/[{}]/, "").split(",").map(&:to_i)

      # Keep the first (oldest) record, remove the rest
      ids_to_remove = ids[1..]

      Rails.logger.info "Removing #{ids_to_remove.length} duplicate(s) for email: #{email}"

      EmailSignup.where(id: ids_to_remove).delete_all
      total_removed += ids_to_remove.length
    end

    Rails.logger.info "Removed #{total_removed} duplicate email signups"
    total_removed
  end
end
