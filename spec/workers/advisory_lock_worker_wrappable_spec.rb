require 'spec_helper'
require 'sidekiq/testing'
require_relative '../../workers/advisory_lock_worker_wrappable'

class TestWorker
  include Sidekiq::Worker
  prepend AdvisoryLockWorkerWrappable

  sidekiq_options retry: false, queue: :test_worker

  def perform(*args) end
end

RSpec.describe AdvisoryLockWorkerWrappable do
  let(:worker) { TestWorker.new }
  let(:lock_query) { "SELECT pg_advisory_xact_lock(?)" }
  let(:lock_value) { TestWorker.name.hash }
  let(:fixed_lock_value) { 1234567890 }

  before do
    allow(DB).to receive(:[]).with(lock_query, TestWorker.name.hash).and_return(DB["SELECT 1"])
    allow_any_instance_of(TestWorker).to receive(:super)
  end

  describe '#perform' do
    it 'acquires the advisory lock and performs the job' do
      worker.perform

      expect(DB).to have_received(:[]).with(lock_query, lock_value)
    end

    it 'logs an error when acquiring the lock fails' do
      allow(DB).to receive(:[]).with(lock_query, lock_value).and_raise(Sequel::DatabaseError.new('DB error'))
      expect(Sidekiq.logger).to receive(:error).with("Failed to acquire lock TestWorker: DB error")

      worker.perform
    end
  end
end
