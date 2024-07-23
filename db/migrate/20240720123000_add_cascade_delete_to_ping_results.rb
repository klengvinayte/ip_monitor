Sequel.migration do
  change do
    alter_table(:ping_results) do
      drop_foreign_key :ip_address_id
      add_foreign_key :ip_address_id, :ip_addresses, on_delete: :cascade
    end
  end
end
