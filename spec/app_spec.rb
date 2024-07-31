require 'spec_helper'
require 'json'

RSpec.describe App, type: :request do
  let(:ip_address) { '192.168.1.1' }
  let(:valid_params) { { ip: ip_address, enabled: true, enabled_since: '2024-02-01', disabled_at: Time.now } }
  let(:invalid_params) { { ip: 'invalid_ip', enabled: true } }

  describe 'POST /ips' do
    context 'when IP address does not exist' do
      it 'creates a new IP address' do
        post '/ips', valid_params.to_json, { 'CONTENT_TYPE' => 'application/json' }
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['ip']).to eq(ip_address)
      end
    end

    context 'when IP address already exists' do
      before do
        IPAddress.create(valid_params)
      end

      it 'returns a 409 status and error message' do
        post '/ips', valid_params.to_json, { 'CONTENT_TYPE' => 'application/json' }
        expect(last_response.status).to eq(409)
        expect(JSON.parse(last_response.body)['error']).to eq('Duplicate IP Address')
      end
    end

    context 'with invalid params' do
      it 'returns a validation error' do
        post '/ips', invalid_params.to_json, { 'CONTENT_TYPE' => 'application/json' }
        expect(last_response.status).to eq(422)
        expect(JSON.parse(last_response.body)['error']).to eq('Validation Failed')
      end
    end
  end

  describe 'POST /ips/:id/enable' do
    let(:ip) { IPAddress.create(valid_params) }

    it 'enables the IP address' do
      post "/ips/#{ip.id}/enable"
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['enabled']).to be_truthy
    end
  end

  describe 'POST /ips/:id/disable' do
    let(:ip) { IPAddress.create(valid_params) }

    it 'disables the IP address' do
      post "/ips/#{ip.id}/disable"
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['enabled']).to be_falsey
    end
  end

  describe 'GET /ips/:id/stats' do
    context 'when no data is available' do
      let(:ip) { IPAddress.create(valid_params) }

      it 'returns an error message' do
        get "/ips/#{ip.id}/stats?time_from=2024-01-01&time_to=2024-07-19"
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['error']).to eq('No active periods found')
      end
    end

    context 'when data is available' do
      let(:ip) { IPAddress.create(valid_params) }

      before do
        # Create sample ping results
        DB[:ping_results].insert(success: true, rtt: 100.0, created_at: '2024-02-01', ip_address_id: ip.id, duration: 0.1)
        DB[:ping_results].insert(success: true, rtt: 200.0, created_at: '2024-03-01', ip_address_id: ip.id, duration: 0.2)
        DB[:ping_results].insert(success: false, rtt: nil, created_at: '2024-04-01', ip_address_id: ip.id, duration: 0.3)
      end

      it 'returns the statistics for the IP address' do
        get "/ips/#{ip.id}/stats?time_from=2024-01-01&time_to=2024-07-31"
        expect(last_response.status).to eq(200)
        stats = JSON.parse(last_response.body)

        # Проверьте, что возвращаемый JSON содержит правильные ключи и значения
        expect(stats).to include('mean_rtt', 'min_rtt', 'max_rtt', 'median_rtt', 'std_dev_rtt', 'packet_loss')

        # Проверьте значения, если вы знаете, какие они должны быть
        expect(stats['mean_rtt'].to_f).to be_within(0.1).of(150.0)
        expect(stats['min_rtt'].to_f).to eq(100.0)
        expect(stats['max_rtt'].to_f).to eq(200.0)
        expect(stats['packet_loss'].to_f).to be_within(0.1).of(33.33)
      end
    end

    context 'when invalid time range is provided' do
      let(:ip) { IPAddress.create(valid_params) }

      it 'returns an error message' do
        get "/ips/#{ip.id}/stats?time_from=invalid_date&time_to=invalid_date"
        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['error']).to eq('Invalid Time Format')
      end
    end
  end

  describe 'DELETE /ips/:id' do
    let(:ip) { IPAddress.create(valid_params) }

    it 'deletes the IP address' do
      delete "/ips/#{ip.id}"
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['message']).to eq('IP address deleted')
    end
  end
end
