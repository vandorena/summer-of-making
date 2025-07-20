Rails.application.configure do
  # Set ActiveStorage analysis jobs to run on literally_whenever queue
  config.active_storage.queues.analysis = :literally_whenever
  config.active_storage.queues.purge = :literally_whenever
end
