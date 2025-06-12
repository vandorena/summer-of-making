Honeybadger.configure do |config|
  @error_counts = Hash.new { |hash, key| hash[key] = { hourly: [], daily: [] } }
  @error_class_counts = Hash.new { |hash, key| hash[key] = { hourly: [], daily: [] } }

  # Rate limiting configuration
  MAX_ERRORS_PER_HOUR = 10
  MAX_ERRORS_PER_DAY = 50

  config.before_notify do |notice|
    error_index = error_index_key notice
    error_class = notice.error_class

    should_ignore = rate_limit_exceeded?(error_index, error_class)
    record_error_occurrence(error_index, error_class) unless should_ignore

    !should_ignore
  end

  private

  def error_index_key(error)
    if error.backtrace.any?
      first_stack_line = notice.backtrace.first
      "#{notice.error_class}:#{first_stack_line}"
    else
      controller = notice.context[:controller]
      action = notice.context[:action]
      "#{notice.error_class}:#{controller}:#{action}"
    end
  end

  def rate_limit_exceeded?(error_index, error_class)
    @error_counts[error_index][:hourly].reject! { |t| t < 1.hour.ago }
    @error_counts[error_index][:daily].reject! { |t| t < 1.day.ago }
    @error_class_counts[error_class][:hourly].reject! { |t| t < 1.hour.ago }
    @error_class_counts[error_class][:daily].reject! { |t| t < 1.day.ago }

    hourly_count = @error_counts[error_index][:hourly].count
    daily_count = @error_counts[error_index][:daily].count
    hourly_class_count = @error_class_counts[error_class][:hourly].count
    daily_class_count = @error_class_counts[error_class][:daily].count

    hourly_count > MAX_ERRORS_PER_HOUR ||
      daily_count > MAX_ERRORS_PER_DAY ||
      hourly_class_count > MAX_ERRORS_PER_HOUR ||
      daily_class_count > MAX_ERRORS_PER_DAY
  end

  def record_error_occurrence(error_index, error_class)
    @error_counts[error_index][:hourly]       << Time.current
    @error_counts[error_index][:daily]        << Time.current
    @error_class_counts[error_class][:hourly] << Time.current
    @error_class_counts[error_class][:daily]  << Time.current
  end
end
