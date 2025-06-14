require "open-uri"

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
      downloaded_image = image_uri.open(
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
      )
      File.binwrite(filepath, downloaded_image.read)
      return "/temp/hsr/#{filename}"
    rescue => e
      Rails.logger.error("fucky wucky while yoinking #{url} #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
    end

    nil
  end
end
