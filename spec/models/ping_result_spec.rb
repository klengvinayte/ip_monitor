require 'spec_helper'

RSpec.describe PingResult, type: :model do
  let(:ip_address) { IPAddress.create(ip: '192.168.1.1', enabled: true) }

  describe 'associations' do
    it 'belongs to an IP address' do
      ping_result = PingResult.create(success: true, duration: 1.23, rtt: 150, ip_address_id: ip_address.id)
      expect(ping_result.ip_address_id).to eq(ip_address.id)
    end
  end
end
