class IPAddress < Sequel::Model
  one_to_many :ping_results

  def to_json
    {
      id: id,
      ip: ip,
      enabled: enabled
    }.to_json
  end

  def validate
    super
    errors.add(:ip, 'is not a valid IPv4 or IPv6 address') unless valid_ip?(ip)
  end

  def active_periods(time_from, time_to)
    periods = []

    # Get all ping results for the IP address within the specified time range
    ping_results_dataset.where(created_at: time_from..time_to).order(:created_at).each do |ping_result|
      if ping_result.success
        periods << { start: ping_result.created_at, end: ping_result.created_at }
      else
        # If the last ping was unsuccessful, the period is over
        periods.last[:end] = ping_result.created_at if periods.any?
      end
    end

    # If the last ping was successful, the period is still active
    periods.last[:end] = time_to if periods.any? && periods.last[:end] < time_to

    merged_periods = merge_intervals(periods)

    merged_periods
  end

  private

  def merge_intervals(intervals)
    return [] if intervals.empty?

    # Sort intervals by start time
    sorted_intervals = intervals.sort_by { |interval| interval[:start] }
    merged_intervals = []

    sorted_intervals.each do |interval|
      if merged_intervals.empty? || merged_intervals.last[:end] < interval[:start]
        # If there are no intersections, add the interval to the result
        merged_intervals << interval
      else
        # If there is an intersection, merge the intervals
        merged_intervals.last[:end] = [merged_intervals.last[:end], interval[:end]].max
      end
    end

    merged_intervals
  end

  def valid_ip?(ip)
    IPAddr.new(ip)
    true
  rescue IPAddr::InvalidAddressError
    false
  end
end
