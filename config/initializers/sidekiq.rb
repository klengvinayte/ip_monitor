# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://localhost:6379/0', network_timeout: 10 }
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://localhost:6379/0', network_timeout: 10 }
end
