Sequel.migration do
  change do
    alter_table(:ip_addresses) do
      add_column :enabled_since, DateTime, null: true
      add_column :disabled_at, DateTime, null: true
    end
  end
end
