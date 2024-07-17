Sequel.migration do
  change do
    alter_table(:ping_results) do
      set_column_type :rtt, BigDecimal
      set_column_not_null :success
      set_column_not_null :created_at
    end

    alter_table(:ip_addresses) do
      set_column_not_null :enabled
    end
  end
end
