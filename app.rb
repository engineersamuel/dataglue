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

# https://github.com/brianmario/mysql2
#
get '/db/info:ref?:schema?:table?' do
  content_type :json
  #logger.info "test"

  # The reference name to the database connection
  ref = params[:ref] || nil
  schema = params[:schema] || nil
  table = params[:table] || nil
  sql = nil

  # If the ref is nil that means list all database connections and available schemas
  if ref.nil?
    DataGlueSettings::db_refs.keys.to_json || []
  else
    # If no schema given then this is a query to see what schemas are available
    if schema.nil?
      sql = 'SELECT SCHEMA_NAME AS `schema` FROM INFORMATION_SCHEMA.SCHEMATA'
      # If a schema given and not table then this is a query to get the tables within that schema
    elsif schema && table.nil?
      sql = "SHOW TABLES FROM #{schema}"
    elsif schema && table
      sql = "SHOW COLUMNS FROM #{schema}.#{table}"
    end
    return DatabaseManagerModule::query(ref, sql).to_a.to_json || []
  end
end

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
