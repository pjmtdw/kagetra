require_relative './helper'
Sequel.migration do
  change do
    create_table_custom(:my_confs,[:base]) do
      String :name, size:64, unique:true
      String :value, text:true
    end
  end
end
