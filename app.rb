# require rubygems and sinatra so you can run this application locally with ruby app.rb
require 'rubygems'
require 'sinatra'
require 'json'
require 'cgi'
require 'awesome_print'
require 'rack/deflater'
require_relative 'src/dataglue/utils/settings'
require_relative 'src/dataglue/db/database_manager_module'
require_relative 'src/dataglue/lib/core/core_extensions'

include DataGlueSettings
include DatabaseManagerModule

use Rack::Deflater

if ENV['OPENSHIFT_DATA_DIR'].nil?
  p 'Disabling cache in development'
  before do
    cache_control :no_cache, :must_revalidate
  end
end

get '/' do
  File.read(File.join('public', 'index.html'))
end

get '/agent' do
  "you're using #{request.user_agent}"
end

get '/settings' do
  DataGlueSettings::config['env']
end
########################################################################################################################
# Backend cache for client side data sets / cache / graph data / ect..
########################################################################################################################
post '/cache' do
  content_type :json
  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read
  doc = data['doc'].is_a?(Hash) ? data['doc'] : JSON.parse(data['doc'])

  #logger.ap_debug(doc)
  # Remember the BSON::ObjectId
  {
    :_id => DatabaseManagerModule::cache_upsert(doc)
  }.to_json
end
get '/cache/:_id' do
  content_type :json
  DatabaseManagerModule::cache_get(params[:_id]).to_json || {}
end

# https://github.com/brianmario/mysql2
########################################################################################################################
# Informational queries
########################################################################################################################
# Get list of database connection references
get '/db/info:ref?:schema?:table?' do
  content_type :json
  DataGlueSettings::db_refs.keys.to_json || []
end
# Get schemas
get '/db/info/:ref' do
  content_type :json
  sql = 'SELECT SCHEMA_NAME AS `schema` FROM INFORMATION_SCHEMA.SCHEMATA'
  return DatabaseManagerModule::query(params[:ref], sql).to_a.to_json || []
end
# Get tables
get '/db/info/:ref/:schema' do
  content_type :json
  #sql = "SHOW TABLES FROM #{params[:schema]}"
  sql = "SELECT DISTINCT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '#{params[:schema]}'"
  return DatabaseManagerModule::query(params[:ref], sql).to_a.to_json || []
end
# Get fields
get '/db/info/:ref/:schema/:table' do
  content_type :json
  #sql = "SHOW COLUMNS FROM `#{params[:schema]}`.`#{params[:table]}`"
  sql = "SELECT COLUMN_NAME, DATA_TYPE, COLUMN_KEY, COLUMN_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '#{params[:schema]}' AND TABLE_NAME = '#{params[:table]}'"
  return DatabaseManagerModule::query(params[:ref], sql).to_a.to_json || []
end
########################################################################################################################

post '/db/query' do
  content_type :json
  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read

  # The reference name to the database connection
  ap data
  sql = Base64.decode64(data['b64_sql']).strip()
  single = data['single'].to_bool

  DatabaseManagerModule::query(data['ref'], sql, single).to_a.to_json || []
end

post '/db/query/:ref/:schema/:table' do
  content_type :json
  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read

  # TODO allow selecting 1..n fields, need to be able to exclude fields
  ## The reference name to the database connection
  fields = data['fields']

  DatabaseManagerModule::query_dynamic(params[:ref], params[:schema], params[:table], fields).to_a.to_json || []
end

post '/dataset/query/' do
  content_type :json
  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read
  doc = data['doc'].is_a?(Hash) ? data['doc'] : JSON.parse(data['doc'])

  DatabaseManagerModule::query_dataset(doc).to_json || []
end

