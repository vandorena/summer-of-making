DeviceDetector.configure do |config|
    config.max_cache_keys = 1_00 # trying to figure out memory leaks
  end
