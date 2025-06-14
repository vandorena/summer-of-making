class DownloadAirtableImageJob < ApplicationJob
  queue_as :default

  def perform(url)
    return nil if url.blank?

    # ruhaurh8awg7ueh8w8he89w9eh8awh8i
    filename = "highseas_review_#{Digest::MD5.hexdigest(url)}.jpg"
    filepath = Rails.root.join("public", "temp", "hsr", filename)
    FileUtils.mkdir_p(File.dirname(filepath))

    # this should download the image, keyword should
    begin
      response = Faraday.get(url)

      if response.success?
        File.binwrite(filepath, response.body)
        return "/temp/hsr/#{filename}"
      end
    rescue StandardError => e
      Rails.logger.error("fucky wucky while yoinking #{url} #{e.message}")
    end

    nil
  end
end
