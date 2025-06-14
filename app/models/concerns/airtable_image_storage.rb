module AirtableImageStorage
  extend ActiveSupport::Concern

  def store_image_locally(url)
    return nil if url.blank?
    # pls work pls work
    DownloadAirtableImageJob.perform_now(url)
  end
end
