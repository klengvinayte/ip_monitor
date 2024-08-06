# frozen_string_literal: true

require 'timeout'
require 'net/ping'
require 'sidekiq'
require 'sidekiq-scheduler'
require_relative '../workers/ping_executor'

# Service to ping IP addresses.
# Pings all enabled IP addresses.
# Pings are performed in parallel using the PingExecutor worker.
class PingService
  include Sidekiq::Worker

  sidekiq_options retry: false, queue: :ping_service

  EXECUTORS_COUNT = 10

  def perform
    self.class.perform_checks
  end

  def self.perform_checks
    ip_ids = IPAddress.where(enabled: true).select_map(:id)

    ip_ids.each_slice(EXECUTORS_COUNT) do |group|
      PingExecutor.perform_async(group)
    end
  end

  def self.ping(ip_address)
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
  end
end
