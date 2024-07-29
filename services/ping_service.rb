require 'timeout'
require 'net/ping'
require_relative '../workers/ping_worker'

class PingService
  include Sidekiq::Worker

  def perform
    self.class.perform_checks
  end

  def self.ping(ip_address)
    pinger = Net::Ping::External.new(ip_address.ip)
    pinger.timeout = 1 # 1 second timeout

    begin
      # We wrap the ping operation in a timeout block to ensure that it doesn't hang
      Timeout.timeout(pinger.timeout) do
        result = pinger.ping
        duration = pinger.duration
        success = result && duration <= pinger.timeout
        PingResult.create(ip_address_id: ip_address.id, success: success, rtt: success ? duration : nil, created_at: Time.now)
      end
    rescue Timeout::Error
      # If the ping operation times out, we consider it a failure
      PingResult.create(ip_address_id: ip_address.id, success: false, created_at: Time.now)
    end
  end

  def self.perform_checks
    IPAddress.where(enabled: true).each do |ip_address|
      PingWorker.perform_async(ip_address.id)

    end
  end
end
