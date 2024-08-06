# frozen_string_literal: true

# Represents an IP address that can be pinged.
# An IP address can have many ping results.
class IPAddress < Sequel::Model
  one_to_many :ping_results

  def to_json(*_args)
    {
      id:,
      ip:,
      enabled:
    }.to_json
  end

  def validate
    super
    errors.add(:ip, 'is not a valid IPv4 or IPv6 address') unless valid_ip?(ip)
  end

  private

  def valid_ip?(ip)
    IPAddr.new(ip)
    true
  rescue IPAddr::InvalidAddressError
    false
  end
end
