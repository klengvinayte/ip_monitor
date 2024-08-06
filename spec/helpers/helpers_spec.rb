# frozen_string_literal: true

require 'spec_helper'
require 'sinatra/base'
require 'rack/test'
require_relative '../../helpers/helpers'

RSpec.describe Helpers do
  include Rack::Test::Methods
  include Helpers

  def app
    Sinatra.new do
      helpers Helpers

      get '/validate_time' do
        time_from = validate_time_param(params[:time_from], 'time_from')
        time_to = validate_time_param(params[:time_to], 'time_to')
        { time_from:, time_to: }.to_json
      end
    end
  end

  describe '#validate_time_param' do
    context 'with valid time' do
      it 'returns the parsed time' do
        time_str = '2024-01-01T00:00:00Z'
        result = validate_time_param(time_str, 'time_from')
        expect(result).to eq(Time.parse(time_str))
      end
    end

    context 'with invalid time' do
      it 'raises an error for invalid time format' do
        get '/validate_time', time_from: 'invalid_time', time_to: '2024-01-01T00:00:00Z'
        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['error']).to eq('Invalid Time Format')
      end
    end

    context 'when parameter is missing' do
      it 'raises an error for missing parameter' do
        get '/validate_time', time_to: '2024-01-01T00:00:00Z'
        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['error']).to eq('Missing Parameter')
      end
    end
  end
end
