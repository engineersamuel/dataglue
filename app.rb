# require rubygems and sinatra so you can run this application locally with ruby app.rb
require 'rubygems'
require 'sinatra'
require 'json'
require 'cgi'
require_relative 'src/dataglue/utils/settings'
require_relative 'src/dataglue/db/database_manager_module'

include DataGlueSettings
include DatabaseManagerModule

get '/' do
  File.read(File.join('public', 'index.html'))
end

get '/agent' do
  "you're using #{request.user_agent}"
end

get '/settings' do
  DataGlueSettings::config['env']
end

# https://github.com/brianmario/mysql2
get '/kcsdw' do
  DatabaseManagerModule::mysql_query('kcsdw', 'SELECT * FROM sfdc_users LIMIT 50').to_a.to_json || []
end