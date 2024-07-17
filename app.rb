require 'sinatra'
require 'sequel'
require 'json'
require 'rufus-scheduler'
require 'net/ping'
require 'dotenv'
require 'pg'

Dotenv.load

DB = Sequel.connect(
  "postgres://#{ENV['POSTGRES_USER']}:#{ENV['POSTGRES_PASSWORD']}@db:5432/#{ENV['POSTGRES_DB']}"
)

require './models/ip_address'
require './models/ping_result'
require './services/ping_service'
require './services/statistics_service'

class App < Sinatra::Base
  before do
    content_type :json
  end

  post '/ips' do
    data = JSON.parse(request.body.read)
    ip = IPAddress.create(enabled: data['enabled'], ip: data['ip'])
    ip.to_json
  end

  get '/ips' do
    ip_addresses = IPAddress.all
    ip_addresses.to_json
  end

  post '/ips/:id/enable' do
    ip = IPAddress[params[:id]]
    if ip
      ip.update(enabled: true)
      ip.to_json
    else
      halt 404, { error: 'IP Address not found' }.to_json
    end
  end

  post '/ips/:id/disable' do
    ip = IPAddress[params[:id]]
    if ip
      ip.update(enabled: false)
      ip.to_json
    else
      halt 404, { error: "IP Address not found" }.to_json
    end
  end

  get '/ips/:id/stats' do
    ip = IPAddress[params[:id]]
    if ip
      time_from = Time.parse(params[:time_from])
      time_to = Time.parse(params[:time_to])
      stats = StatisticsService.calculate(ip, time_from, time_to)
      stats.to_json
    else
      halt 404, { error: 'IP Address not found' }.to_json
    end
  end

  delete '/ips/:id' do
    ip = IPAddress[params[:id]]
    halt 404 unless ip
    ip.destroy
    { message: 'IP address deleted' }.to_json
  end
end

# Запуск планировщика
scheduler = Rufus::Scheduler.new

scheduler.every '1m' do
  PingService.perform_checks
end

# run App.run!
