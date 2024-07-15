class PingResult < Sequel::Model
  many_to_one :ip_address
end
