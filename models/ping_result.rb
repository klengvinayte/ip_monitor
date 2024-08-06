# frozen_string_literal: true

# Represents the result of a ping operation.
# Associates with an IP address.
class PingResult < Sequel::Model
  many_to_one :ip_address
end
