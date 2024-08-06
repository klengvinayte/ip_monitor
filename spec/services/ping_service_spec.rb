# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'
require 'timeout'
require 'net/ping'
require_relative '../../services/ping_service'
require_relative '../../models/ip_address'
require_relative '../../models/ping_result'

Sidekiq::Testing.fake!

RSpec.describe PingService, type: :worker do
  let(:ip_address) { IPAddress.create(ip: '192.168.1.1', enabled: true) }
  let(:ip_address_disabled) { IPAddress.create(ip: '192.168.1.2', enabled: false) }

  describe '#perform' do
    it 'calls perform_checks' do
      expect(PingService).to receive(:perform_checks)
      PingService.new.perform
    end
  end

  describe '.perform_checks' do
    it 'queues PingExecutor jobs for enabled IP addresses' do
      ip_address # Ensure IP address is created
      expect do
        PingService.perform_checks
      end.to change(PingExecutor.jobs, :size).by(1)
    end

    it 'does not queue PingExecutor jobs for disabled IP addresses' do
      ip_address_disabled # Ensure disabled IP address is created
      expect do
        PingService.perform_checks
      end.not_to change(PingExecutor.jobs, :size)
    end
  end

  describe '.ping' do
    context 'when the ping is successful' do
      it 'creates a successful PingResult' do
        allow_any_instance_of(Net::Ping::External).to receive(:ping).and_return(true)
        allow_any_instance_of(Net::Ping::External).to receive(:duration).and_return(0.5)

        expect do
          PingService.ping(ip_address)
        end.to change { PingResult.where(success: true).count }.by(1)

        result = PingResult.last
        expect(result.rtt).to eq(0.5)
        expect(result.ip_address_id).to eq(ip_address.id)
      end
    end

    context 'when the ping times out' do
      it 'creates an unsuccessful PingResult' do
        allow_any_instance_of(Net::Ping::External).to receive(:ping).and_return(false)

        expect do
          PingService.ping(ip_address)
        end.to change { PingResult.where(success: false).count }.by(1)

        result = PingResult.last
        expect(result.rtt).to be_nil
        expect(result.ip_address_id).to eq(ip_address.id)
      end
    end

    context 'when the ping duration exceeds the timeout' do
      it 'creates an unsuccessful PingResult' do
        allow_any_instance_of(Net::Ping::External).to receive(:ping).and_return(true)
        allow_any_instance_of(Net::Ping::External).to receive(:duration).and_return(2)

        expect do
          PingService.ping(ip_address)
        end.to change { PingResult.where(success: false).count }.by(1)

        result = PingResult.last
        expect(result.rtt).to be_nil
        expect(result.ip_address_id).to eq(ip_address.id)
      end
    end

    context 'when a Timeout::Error is raised' do
      it 'creates an unsuccessful PingResult' do
        allow_any_instance_of(Net::Ping::External).to receive(:ping).and_raise(Timeout::Error)

        expect do
          PingService.ping(ip_address)
        end.to change { PingResult.where(success: false).count }.by(1)

        result = PingResult.last
        expect(result.rtt).to be_nil
        expect(result.ip_address_id).to eq(ip_address.id)
      end
    end
  end
end
