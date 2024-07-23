require 'spec_helper'

RSpec.describe IPAddress, type: :model do
  let(:valid_ip) { 'fe80::1ff:fe23:4568:890a' }
  let(:invalid_ip) { 'invalid_ip' }

  describe 'validations' do
    it 'is valid with a valid IP address' do
      ip = IPAddress.new(ip: valid_ip, enabled: true)
      expect(ip.valid?).to be_truthy
    end

    it 'is invalid with an invalid IP address' do
      ip = IPAddress.new(ip: invalid_ip, enabled: true)
      expect(ip.valid?).to be_falsey
      expect(ip.errors[:ip]).to include('is not a valid IPv4 or IPv6 address')
    end
  end

  describe '#to_json' do
    it 'returns the correct JSON representation' do
      ip = IPAddress.create(ip: valid_ip, enabled: true)
      json = JSON.parse(ip.to_json)
      expect(json['id']).to eq(ip.id)
      expect(json['ip']).to eq(valid_ip)
      expect(json['enabled']).to eq(true)
    end
  end
end
