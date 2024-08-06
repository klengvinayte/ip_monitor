# frozen_string_literal: true

require 'sidekiq'
require_relative 'advisory_lock_worker_wrappable'
require_relative '../services/ping_service'

# Worker to ping IP addresses.
# Pings all enabled IP addresses.
# Pings are performed in parallel using the PingExecutor worker.
class PingExecutor
  include Sidekiq::Worker
  prepend AdvisoryLockWorkerWrappable

  sidekiq_options retry: false, queue: :ping_executor

  def perform(ip_ids)
    IPAddress.where(id: ip_ids).each do |ip_address|
      PingService.ping(ip_address)
    end
  end
end
