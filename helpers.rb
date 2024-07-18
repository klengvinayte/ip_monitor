# helpers.rb
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
end
