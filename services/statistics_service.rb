class StatisticsService
  def self.calculate(ip_address, time_from, time_to)
    results = ip_address.ping_results_dataset.where(created_at: time_from..time_to).all

    return { error: 'No data available for the given period' } if results.empty?

    rtts = results.select(&:success).map(&:rtt)

    return { error: 'No valid RTT data available' } if rtts.empty?

    mean = rtts.sum / rtts.size
    min = rtts.min
    max = rtts.max
    sorted_rtts = rtts.sort
    median = sorted_rtts[rtts.size / 2]
    variance = rtts.map { |rtt| (rtt - mean) ** 2 }.sum / rtts.size
    std_dev = Math.sqrt(variance)
    total_checks = results.size
    failed_checks = results.count { |result| !result.success }
    packet_loss = 100.0 * failed_checks / total_checks

    {
      mean_rtt: mean,
      min_rtt: min,
      max_rtt: max,
      median_rtt: median,
      std_dev_rtt: std_dev,
      packet_loss: packet_loss
    }
  end
end
