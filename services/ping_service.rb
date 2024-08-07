# frozen_string_literal: true

require 'timeout'
require 'net/ping'
require 'sidekiq'
require 'sidekiq-scheduler'
require 'logger'
require_relative '../workers/ping_executor'
require_relative 'logging'

# Service to ping IP addresses.
# Pings all enabled IP addresses.
# Pings are performed in parallel using the PingExecutor worker.
class PingService
  include Sidekiq::Worker
  include Logging

  sidekiq_options retry: false, queue: :ping_service

  EXECUTORS_COUNT = 10

  def perform
    logger.info("Starting PingService perform at #{Time.now}")
    self.class.perform_checks
    logger.info("Finished PingService perform at #{Time.now}")
  rescue StandardError => e
    logger.error("Error in PingService perform: #{e.message}")
  end

  def self.perform_checks
    ip_ids = IPAddress.where(enabled: true).select_map(:id)
    logger.info("Pinging IPs: #{ip_ids}")

    ip_ids.each_slice(EXECUTORS_COUNT) do |group|
      PingExecutor.perform_async(group)
    end
  rescue StandardError => e
    logger.error("Error in perform_checks: #{e.message}")
  end

  def self.ping(ip_address)
    logger.info("Pinging IP address #{ip_address.ip}")
    pinger = Net::Ping::External.new(ip_address.ip)
    pinger.timeout = 1 # 1 second timeout

    begin
      Timeout.timeout(pinger.timeout) do
        result = pinger.ping
        duration = pinger.duration
        success = result && duration <= pinger.timeout
        PingResult.create(ip_address_id: ip_address.id, success:, rtt: success ? duration : nil,
                          created_at: Time.now)
      end
    rescue Timeout::Error
      PingResult.create(ip_address_id: ip_address.id, success: false, created_at: Time.now)
    end
  rescue StandardError => e
    logger.error("Error pinging IP address #{ip_address.ip}: #{e.message}")
  end
end
