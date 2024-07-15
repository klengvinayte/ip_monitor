Sequel.migration do
  change do
    create_table(:ip_addresses) do
      primary_key :id
      String :ip, null: false, unique: true
      Boolean :enabled, default: false
    end
  end
end
