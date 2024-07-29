require './services/ping_service'
require './models/ip_address'

class PingWorker
  include Sidekiq::Worker

  def perform(ip_address_id)
    ip_address = IPAddress[ip_address_id]
    PingService.ping(ip_address)
  end
end
