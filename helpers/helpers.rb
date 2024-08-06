# frozen_string_literal: true

# Represents an IP address that can be pinged.
# An IP address can have many ping results.
module Helpers
  def json_params
    JSON.parse(request.body.read)
  rescue JSON::ParserError
    halt 400, { error: 'Invalid JSON' }.to_json
  end

  def ip_not_found
    halt 404, { error: 'IP Address not found' }.to_json
  end

  def validation_error(resource)
    halt 422, { error: 'Validation Failed', details: resource.errors.full_messages }.to_json
  end

  def validate_time_param(time_param, name)
    if time_param
      begin
        Time.parse(time_param)
      rescue ArgumentError
        halt 400, { error: 'Invalid Time Format', details: "The #{name} parameter is not a valid time." }.to_json
      end
    else
      halt 400, { error: 'Missing Parameter', details: "The #{name} parameter is required." }.to_json
    end
  end
end
