Sequel.migration do
  change do
    alter_table(:ping_results) do
      add_column :rtt, :float
    end
  end
end
