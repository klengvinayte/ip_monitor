module AdvisoryLockWorkerWrappable
  def perform(*args)
    DB.transaction do
      # Acquire an exclusive lock on the class name
      DB["SELECT pg_advisory_xact_lock(?)", self.class.name.hash].all
      super(*args)
    end
  rescue Sequel::DatabaseError => e
    Rails.logger.error("Failed to acquire lock #{self.class.name}: #{e.message}")
  end
end
