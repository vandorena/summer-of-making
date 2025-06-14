class DownloadAirtableImageJob < ApplicationJob
  queue_as :default

  def perform(url)
    return nil if url.blank?

    # ruhaurh8awg7ueh8w8he89w9eh8awh8i
    filename = "highseas_review_#{Digest::MD5.hexdigest(url)}.jpg"
    filepath = Rails.root.join("public", "temp", "hsr", filename)
    FileUtils.mkdir_p(File.dirname(filepath))

    # do it in a normal way
    begin
      image_uri = URI.parse(url)
      downloaded_image = image_uri.open
      File.binwrite(filepath, downloaded_image.read)
      return "/temp/hsr/#{filename}"
    rescue => e
      Rails.logger.error("fucky wucky while yoinking #{url} #{e.message}")
    end

    nil
  end
end
