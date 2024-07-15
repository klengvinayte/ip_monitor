Sequel.migration do
  change do
    create_table(:ping_results) do
      primary_key :id
      foreign_key :ip_address_id, :ip_addresses
      Boolean :success, null: false
      Float :duration
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
