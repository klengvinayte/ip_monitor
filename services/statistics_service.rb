# frozen_string_literal: true

# This service is responsible for calculating statistics for a given IP address
# over a specified time range.
# It fetches the active periods for the IP address and then calculates the statistics
class StatisticsService
  def self.calculate(ip_address, time_from, time_to)
    periods = fetch_periods(ip_address, time_from, time_to)

    # If there are no active periods, return an error
    return { error: 'No active periods found' } if periods.empty?

    combined_start = periods.map { |p| p[:start_time] }.min
    combined_end = periods.map { |p| p[:end_time] }.max

    stats_query = <<-SQL
      SELECT#{' '}
        AVG(rtt) AS mean_rtt,
        MIN(rtt) AS min_rtt,
        MAX(rtt) AS max_rtt,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rtt) AS median_rtt,
        STDDEV(rtt) AS std_dev_rtt,
        COUNT(*) AS total_checks,
        SUM(CASE WHEN success = false THEN 1 ELSE 0 END) AS failed_checks
      FROM ping_results
      WHERE ip_address_id = ?#{' '}
        AND created_at BETWEEN ? AND ?
    SQL

    results = DB[stats_query, ip_address.id, combined_start, combined_end].first

    if results.nil? || results[:total_checks].to_i.zero?
      return { error: 'No data available for the specified time range' }
    end

    packet_loss = (results[:failed_checks].to_f / results[:total_checks]) * 100.0

    stats = {
      mean_rtt: results[:mean_rtt],
      min_rtt: results[:min_rtt],
      max_rtt: results[:max_rtt],
      median_rtt: results[:median_rtt],
      std_dev_rtt: results[:std_dev_rtt],
      packet_loss:
    }

    stats.each do |key, value|
      stats[key] = value.nan? ? nil : value if value.is_a?(Float)
    end

    stats
  end

  def self.fetch_periods(ip_address, time_from, time_to)
    periods_query = <<-SQL
      WITH pings AS (
        SELECT#{' '}
          created_at,
          success,
          LAG(success) OVER (ORDER BY created_at) AS prev_success
        FROM ping_results
        WHERE ip_address_id = ?#{' '}
          AND created_at BETWEEN ? AND ?
      ),
      periods AS (
        SELECT#{' '}
          created_at AS start_time,
          LEAD(created_at) OVER (ORDER BY created_at) AS end_time
        FROM pings
        WHERE success = TRUE
          AND (prev_success IS NULL OR prev_success = FALSE)
      )
      SELECT start_time,#{' '}
             COALESCE(end_time, ?) AS end_time
      FROM periods
      WHERE end_time IS NOT NULL
      UNION ALL
      SELECT MIN(start_time), ?
      FROM periods
      WHERE end_time IS NULL
      GROUP BY start_time
      ORDER BY start_time;
    SQL

    periods = DB[periods_query, ip_address.id, time_from, time_to, time_to, time_to].all

    # Merge overlapping periods
    merge_intervals(periods)
  end

  def self.merge_intervals(periods)
    merged = []
    periods.sort_by { |p| p[:start_time] }.each do |period|
      if merged.empty? || merged.last[:end_time] < period[:start_time]
        merged << period
      else
        merged.last[:end_time] = [merged.last[:end_time], period[:end_time]].max
      end
    end
    merged
  end
end
