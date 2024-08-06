# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'
require_relative '../../workers/ping_executor'
require_relative '../../models/ip_address'
require_relative '../../services/ping_service'

Sidekiq::Testing.fake!

RSpec.describe PingExecutor, type: :worker do
  let(:ip_address) { IPAddress.create(ip: '192.168.1.1', enabled: true) }
  let(:ip_address_2) { IPAddress.create(ip: '192.168.1.2', enabled: true) }

  describe '#perform' do
    it 'calls PingService.ping for each IP address' do
      ip_ids = [ip_address.id, ip_address_2.id]
      allow(PingService).to receive(:ping)

      PingExecutor.new.perform(ip_ids)

      expect(PingService).to have_received(:ping).with(ip_address)
      expect(PingService).to have_received(:ping).with(ip_address_2)
    end
  end
end
