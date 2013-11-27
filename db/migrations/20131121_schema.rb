Sequel.migration do
  up do
    execute_ddl File.read(__FILE__.to_s.gsub('.rb','.sql'))
  end

  down do
    execute_ddl "drop schema securrity cascade;"
  end
end
