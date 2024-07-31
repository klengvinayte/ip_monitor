module AdvisoryLockWorkerWrappable
  def perform(*args)
    lock_value = self.class.name.hash
    begin
      DB.transaction do
        DB["SELECT pg_advisory_xact_lock(?)", lock_value].all
        super(*args)
      end
    rescue Sequel::DatabaseError => e
      Sidekiq.logger.error("Failed to acquire lock #{self.class.name}: #{e.message}")
    end
  end
end
