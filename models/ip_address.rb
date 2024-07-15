class IPAddress < Sequel::Model
  one_to_many :ping_results

  def before_destroy
    ping_results.each(&:destroy)
  end

  def to_json
    {
      id: id,
      ip: ip,
      enabled: enabled
    }.to_json
  end
end
