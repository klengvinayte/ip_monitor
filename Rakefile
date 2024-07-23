require 'sequel'
require 'sequel/extensions/migration'
require 'dotenv/load'

namespace :db do
  desc 'Run migrations'
  task :migrate do
    DB = Sequel.connect(ENV['DATABASE_URL'])
    Sequel::Migrator.run(DB, 'db/migrate')
  end

  desc 'Rollback the last migration'
  task :rollback do
    DB = Sequel.connect(ENV['DATABASE_URL'])
    Sequel::Migrator.run(DB, 'db/migrate', target: DB[:schema_info].get(:version) - 1)
  end

  desc 'Setup the database'
  task :setup do
    DB = Sequel.connect(ENV['DATABASE_URL'])
    Sequel.extension :migration
    Sequel::Migrator.run(DB, 'db/migrate')
    puts 'Database has been set up successfully!'
  end

  desc 'Dump the current schema'
  task :dump_schema do
    DB = Sequel.connect(ENV['DATABASE_URL'])
    File.open('db/schema.rb', 'w') do |file|
      DB.tables.each do |table|
        schema = DB.schema(table)
        file.puts "create_table(:#{table}) do"
        schema.each do |column|
          name, details = column
          type = details[:db_type]
          opts = []
          opts << "null: #{details[:allow_null]}" unless details[:allow_null].nil?
          opts << "default: #{details[:default]}" unless details[:default].nil?
          opts << "primary_key: true" if details[:primary_key]
          file.puts "  #{name} #{type}, #{opts.join(', ')}"
        end
        file.puts "end\n\n"
      end
    end
    puts 'Schema dumped to db/schema.rb'
  end
end
