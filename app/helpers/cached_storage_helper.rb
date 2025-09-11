# frozen_string_literal: true

module CachedStorageHelper
  def cached_url_for(attachment, expires_in: 50.minutes)
    return nil unless attachment&.attached?

    cache_key = "storage_url/#{attachment.blob.key}/#{attachment.blob.checksum}"

    Rails.cache.fetch(cache_key, expires_in: expires_in) do
      url_for(attachment)
    end
  end
end
