# frozen_string_literal: true

Rails.application.config.after_initialize do
  HackatimeStatRefreshJob.perform_later if defined? Rails::Server
end
