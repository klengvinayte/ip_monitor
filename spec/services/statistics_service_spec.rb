require 'spec_helper'
require 'json'

RSpec.describe StatisticsService do
  let(:ip) { IPAddress.create(ip: '192.168.1.1', enabled: true, enabled_since: '2024-02-01') }

  before do
    DB[:ping_results].delete
  end

  describe '.calculate' do
    context 'when no data is available' do
      it 'returns an error message' do
        result = StatisticsService.calculate(ip, '2024-01-01', '2024-07-19')
        expect(result).to eq({ error: 'No active periods found' })
      end
    end

    context 'when only inactive periods are within range' do
      before do
        DB[:ping_results].insert(success: false, rtt: nil, created_at: '2024-02-01', ip_address_id: ip.id)
        DB[:ping_results].insert(success: false, rtt: nil, created_at: '2024-03-01', ip_address_id: ip.id)
      end

      it 'returns an error message' do
        result = StatisticsService.calculate(ip, '2024-01-01', '2024-07-19')
        expect(result).to eq({ error: 'No active periods found' })
      end
    end

    context 'when data is available' do
      before do
        DB[:ping_results].insert(success: true, rtt: 100.0, created_at: '2024-02-01', ip_address_id: ip.id, duration: 0.1)
        DB[:ping_results].insert(success: true, rtt: 200.0, created_at: '2024-03-01', ip_address_id: ip.id, duration: 0.2)
        DB[:ping_results].insert(success: false, rtt: nil, created_at: '2024-04-01', ip_address_id: ip.id, duration: 0.3)
      end

      it 'returns correct statistics for the IP address' do
        result = StatisticsService.calculate(ip, '2024-01-01', '2024-07-19')
        expect(result).to include(
                            :mean_rtt,
                            :min_rtt,
                            :max_rtt,
                            :median_rtt,
                            :std_dev_rtt,
                            :packet_loss
                          )

        expect(result[:mean_rtt]).to be_within(0.1).of(150.0)
        expect(result[:min_rtt]).to eq(100.0)
        expect(result[:max_rtt]).to eq(200.0)
        expect(result[:packet_loss]).to be_within(0.1).of(33.33)
      end
    end

    context 'when data is available but only for a short period' do
      before do
        DB[:ping_results].insert(success: true, rtt: 100.0, created_at: '2024-02-01', ip_address_id: ip.id, duration: 0.1)
        DB[:ping_results].insert(success: true, rtt: 200.0, created_at: '2024-02-02', ip_address_id: ip.id, duration: 0.2)
      end

      it 'returns statistics even if the period is short' do
        result = StatisticsService.calculate(ip, '2024-01-01', '2024-07-19')
        expect(result).to include(
                            :mean_rtt,
                            :min_rtt,
                            :max_rtt,
                            :median_rtt,
                            :std_dev_rtt,
                            :packet_loss
                          )

        expect(result[:mean_rtt]).to be_within(0.1).of(150.0)
        expect(result[:min_rtt]).to eq(100.0)
        expect(result[:max_rtt]).to eq(200.0)
        expect(result[:packet_loss]).to be_within(0.1).of(0.0)
      end
    end
  end
end
