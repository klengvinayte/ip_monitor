# frozen_string_literal: true

require './services/ping_service'
require './models/ip_address'

# Worker to ping an IP address.
# Pings a single IP address.
# Pings are performed in parallel using the PingWorker worker.
class PingWorker
  include Sidekiq::Worker

  def perform(ip_address_id)
    ip_address = IPAddress[ip_address_id]
    PingService.ping(ip_address)
  end
end
