class ActiveStorageMoveJob < ApplicationJob
    queue_as :default

    def perform(source = "cloudflare", destination = "cloudflare_new")
      blobs = ActiveStorage::Blob.where(service_name: source)

      blobs.find_each do |blob|
        blob.open do |file|
          new_key = ActiveStorage::Blob.generate_unique_secure_token
          service = ActiveStorage::Blob.services.fetch(destination.to_sym)

          service.upload(new_key, file, checksum: blob.checksum)

          blob.update!(key: new_key, service_name: destination)
        end
      end
    end
end
