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
    logger.info("Starting PingExecutor for IPs: #{ip_ids} at #{Time.now}")
    IPAddress.where(id: ip_ids).each do |ip_address|
      PingService.ping(ip_address)
    end
    logger.info("Finished PingExecutor for IPs: #{ip_ids} at #{Time.now}")
  rescue StandardError => e
    logger.error("Error in PingExecutor: #{e.message}")
  end
end
