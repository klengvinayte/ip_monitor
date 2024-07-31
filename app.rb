require 'sinatra'
require 'sequel'
require 'json'
require 'net/ping'
require 'dotenv'
require 'pg'
require 'ipaddr'
require 'sidekiq'
require 'sidekiq-scheduler'
require_relative 'helpers/helpers'

Dotenv.load

DB = Sequel.connect(ENV['DATABASE_URL'], max_connections: 20)

require './models/ip_address'
require './models/ping_result'
require './services/ping_service'
require './services/statistics_service'

class App < Sinatra::Base
  helpers Helpers

  before do
    content_type :json
  end

  post '/ips' do
    data = json_params

    if IPAddress.find(ip: data['ip'])
      halt 409, { error: 'Duplicate IP Address', details: 'The IP address you are trying to add already exists.' }.to_json
    else
      ip = IPAddress.new(enabled: data['enabled'], ip: data['ip'])

      ip.enabled_since = Time.now if ip.enabled

      if ip.valid?
        ip.save
        ip.to_json
      else
        validation_error(ip)
      end
    end
  end

  get '/ips' do
    ip_addresses = IPAddress.all
    ip_addresses.to_json
  end

  post '/ips/:id/enable' do
    ip = IPAddress[params[:id]] || ip_not_found
    ip.update(enabled: true, enabled_since: Time.now)
    ip.to_json
  end

  post '/ips/:id/disable' do
    ip = IPAddress[params[:id]] || ip_not_found
    ip.update(enabled: false, disabled_at: Time.now)
    ip.to_json
  end

  get '/ips/:id/stats' do
    ip = IPAddress[params[:id]] || ip_not_found
    time_from = validate_time_param(params[:time_from], 'time_from')
    time_to = validate_time_param(params[:time_to], 'time_to')

    stats = StatisticsService.calculate(ip, time_from, time_to)
    stats.to_json
  end

  delete '/ips/:id' do
    ip = IPAddress[params[:id]] || ip_not_found
    ip.destroy
    { message: 'IP address deleted' }.to_json
  end
end

# App.run!
