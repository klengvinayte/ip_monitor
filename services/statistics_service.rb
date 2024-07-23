class StatisticsService
  def self.calculate(ip_address, time_from, time_to)
    query = <<-SQL
      SELECT 
        AVG(rtt) AS mean_rtt,
        MIN(rtt) AS min_rtt,
        MAX(rtt) AS max_rtt,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rtt) AS median_rtt,
        STDDEV(rtt) AS std_dev_rtt,
        COUNT(*) AS total_checks,
        SUM(CASE WHEN success = false THEN 1 ELSE 0 END) AS failed_checks
      FROM ping_results
      WHERE ip_address_id = ? 
        AND created_at BETWEEN ? AND ?
    SQL

    results = DB[query, ip_address.id, time_from, time_to].first

    if results.nil? || results[:total_checks].to_i == 0
      return { error: 'No data available for the specified time range' }
    else
      packet_loss = (results[:failed_checks].to_f / results[:total_checks]) * 100.0

      stats = {
        mean_rtt: results[:mean_rtt],
        min_rtt: results[:min_rtt],
        max_rtt: results[:max_rtt],
        median_rtt: results[:median_rtt],
        std_dev_rtt: results[:std_dev_rtt],
        packet_loss: packet_loss
      }

      # Replace NaN values with nil
      stats.each do |key, value|
        stats[key] = value.nan? ? nil : value if value.is_a?(Float)
      end

      stats
    end
  end
end
