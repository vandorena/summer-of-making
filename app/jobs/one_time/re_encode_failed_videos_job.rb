class OneTime::ReEncodeFailedVideosJob < ApplicationJob
  queue_as :literally_whenever

  def perform
    Rails.logger.info "Starting re-encoding of videos that need conversion..."

    ship_certs = ShipCertification.joins(:proof_video_attachment)
                                  .includes(proof_video_attachment: :blob)

    total_count = ship_certs.count
    re_encoded_count = 0
    skipped_count = 0

    Rails.logger.info "Found #{total_count} ship certifications with videos"

    ship_certs.find_each do |ship_cert|
      content_type = ship_cert.proof_video.content_type

      if content_type&.include?("mp4") || content_type&.include?("webm")
        Rails.logger.debug "Skipping ShipCertification #{ship_cert.id} - already web-friendly (#{content_type})"
        skipped_count += 1
        next
      end

      Rails.logger.info "Queueing conversion for ShipCertification #{ship_cert.id} (#{content_type})"
      VideoConversionJob.perform_now(ship_cert.id)
      re_encoded_count += 1
    end

    Rails.logger.info "Re-encoding job completed:"
    Rails.logger.info "  Total videos found: #{total_count}"
    Rails.logger.info "  Queued for re-encoding: #{re_encoded_count}"
    Rails.logger.info "  Skipped (already web-friendly): #{skipped_count}"
  end
end
