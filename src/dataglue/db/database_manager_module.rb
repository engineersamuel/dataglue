require 'rubygems'
require 'mysql2'
require 'awesome_print'
require 'mongo'
require 'active_support/core_ext/hash'
require_relative '../utils/settings'

include Mongo

module DatabaseManagerModule
  #attr_reader :mysql_conns

  #def self.included(base)
  #  @client = MongoClient.new('localhost', 27017, :pool_size => 1)
  #end

  #def self.mysql_conns
  #  @mysql_conns
  #end

  # Input could be 'asdfkajsdlkjasdf' or {'_id' => {'$oid' => 'asdflkajsflkjasdf'}}
  def self.get_mongo_id(input)
    if input.is_a?(String)
      return input
    elsif input.is_a?(Hash)
      if input.has_key?('_id') and input['_id'].has_key?('$oid')
        return input['_id']['$oid']
      elsif input.has_key?('$oid')
        return input['$oid']
      end
    end
  end

  def self.cache_upsert(doc)
    # First sanitize the doc from angular to remove any $$hashKey elements
    doc['dbReferences'].each do |k, v|
      v['fields'].each {|f| f.except!('$$hashKey')}
    end

    db = MongoClient.new(DataGlueSettings::master_ref['host'], DataGlueSettings::master_ref['port'], :pool_size => 1).db(DataGlueSettings::master_ref['db'])
    auth = nil
    if DataGlueSettings::master_ref['user'] and DataGlueSettings::master_ref['user'] != '' && DataGlueSettings::master_ref['pass']
      auth = db.authenticate(DataGlueSettings::master_ref['user'], DataGlueSettings::master_ref['pass'])
    end

    saved_or_updated_id = nil
    # If no _id this is a brand new document
    if doc['_id'].nil? or doc['_id'] == ''
      saved_or_updated_id = db[DataGlueSettings::master_ref['collection']].insert(doc)
      p "New cached document inserted with _id: #{saved_or_updated_id.to_s}"
    else
      #saved_or_updated_id = self.get_mongo_id(doc['_id'])
      saved_or_updated_id = BSON::ObjectId(doc['_id'])
      doc['_id'] = saved_or_updated_id
      p "Existing cached document received with _id: #{doc['_id'].to_s}"
      ap doc
      db[DataGlueSettings::master_ref['collection']].update({:_id => doc['_id']}, doc, opts = {:upsert => true})
    end
    saved_or_updated_id.to_s
  end

  def self.cache_get(_id)
    #_id = self.get_mongo_id(_id)
    db = MongoClient.new(DataGlueSettings::master_ref['host'], DataGlueSettings::master_ref['port'], :pool_size => 1).db(DataGlueSettings::master_ref['db'])
    auth = nil
    if DataGlueSettings::master_ref['user'] and DataGlueSettings::master_ref['user'] != '' && DataGlueSettings::master_ref['pass']
      auth = db.authenticate(DataGlueSettings::master_ref['user'], DataGlueSettings::master_ref['pass'])
    end
    ap _id
    doc = db[DataGlueSettings::master_ref['collection']].find_one({:_id => BSON::ObjectId(_id)})
    if doc
      doc['_id'] = doc['_id'].to_s
    end
    return doc
  end

  def self.mysql_query(ref, sql, single=false)
    host = DataGlueSettings::mysql_refs[ref]['host']
    user = DataGlueSettings::mysql_refs[ref]['user']
    pass = Base64.decode64(DataGlueSettings::mysql_refs[ref]['pass']).strip()
    db = DataGlueSettings::mysql_refs[ref]['db']
    client = Mysql2::Client.new(:host => host, :username => user, :password => pass, :database => db)
    client.query(sql)
  end

  def self.query(ref, sql, single=false)
    ap sql
    type = DataGlueSettings::mysql_refs[ref]['type']
    if type == 'mysql'
      return self.mysql_query(ref, sql, single)
    end
  end

  def self.build_sql_query(ref, schema, table, fields)
    sql = "SELECT #{fields.select {|x| x['fieldOptions'] != 'excluded'}.map {|x| x['COLUMN_NAME']}.join(',')} FROM '#{schema}'.'#{table}' LIMIT 1000"
    sql
  end

  def self.query_dynamic(ref, schema, table, fields)
    type = DataGlueSettings::mysql_refs[ref]['type']
    if type == 'mysql'

      # The fields array should have the type of each field unless we are dealing with NoSQL then it should be provided by the UI or yaml mapping?

      # TODO I will need a more intelligent map to map based on column name

      # Let's first deal with the most basic use of grabbing the data from the reference and sending it back up
      sql = self.build_sql_query(ref, schema, table, fields)

      ap sql
      return self.mysql_query(ref, sql, single)
    end
  end

end
