require 'sequel'
require 'bundler/setup'
require 'rspec'
require 'rack/test'
require 'sidekiq/testing'
require 'dotenv/load'
require_relative '../app'

ENV['RACK_ENV'] = 'test'
ENV['DATABASE_URL'] = ENV['DATABASE_URL_TEST']

# DB = Sequel.connect(ENV['DATABASE_URL'])

RSpec.configure do |config|
  config.include Rack::Test::Methods

  def app
    App
  end

  config.before(:suite) do
    Sequel.extension :migration
    Sequel::Migrator.run(DB, 'db/migrate')
  end

  config.before(:each) do
    DB[:ip_addresses].delete
  end
end
