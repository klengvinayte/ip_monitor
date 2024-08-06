# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'
require_relative '../../workers/ping_worker'
require_relative '../../models/ip_address'
require_relative '../../services/ping_service'

Sidekiq::Testing.fake!

RSpec.describe PingWorker, type: :worker do
  let(:ip_address) { IPAddress.create(ip: '192.168.1.1', enabled: true) }

  describe '#perform' do
    it 'calls PingService.ping with the correct IP address' do
      allow(PingService).to receive(:ping)

      PingWorker.new.perform(ip_address.id)

      expect(PingService).to have_received(:ping).with(ip_address)
    end
  end
end
