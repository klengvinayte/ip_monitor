Sequel.migration do
  change do
    alter_table :ping_results do
      add_index [:created_at, :ip_address_id], name: :idx_ping_results_created_at_ip_address_id
    end
  end
end
