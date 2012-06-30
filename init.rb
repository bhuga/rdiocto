require './env'
require 'bundler'
Bundler.require :default
require 'yaml'

RACK_ENV = ENV['RACK_ENV'] || 'development'

dbs = YAML.load_file('./database.yml')
DB_CONFIG = dbs[RACK_ENV]

ActiveRecord::Base.establish_connection DB_CONFIG

