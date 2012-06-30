require_relative 'init'
require 'sinatra/activerecord/rake'

task :createdb do
  ActiveRecord::Base.establish_connection DB_CONFIG.merge('database' => 'postgres' )
  ActiveRecord::Base.connection.create_database DB_CONFIG['database'],
                              :charset => 'utf8', :collation => 'utf8_unicode_ci'
  ActiveRecord::Base.establish_connection DB_CONFIG
end
