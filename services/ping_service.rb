require 'net/ping'

class PingService
  def self.ping(ip_address)
    pinger = Net::Ping::External.new(ip_address.ip)
    pinger.timeout = 1 # 1 second timeout

    if pinger.ping
      PingResult.create(ip_address_id: ip_address.id, success: true, rtt: pinger.duration, created_at: Time.now)
    else
      PingResult.create(ip_address_id: ip_address.id, success: false, created_at: Time.now)
    end
  end

  def self.perform_checks
    IPAddress.where(enabled: true).each do |ip_address|
      ping(ip_address)
    end
  end
end
