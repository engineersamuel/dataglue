require 'rubygems'
require 'mysql2'
require 'mongo'
require 'json'
require 'snappy'
require 'active_support/core_ext/hash'
require_relative '../utils/settings'
require_relative '../utils/dataglue_logger'
require 'awesome_print'

include Mongo
include Logging

module DatabaseManagerModule
  attr_reader :mongo_client, :coll_refs, :coll_cache

  def self.included(base)
    logger.debug 'Establishing a connection to mongo'
    @mongo_client = MongoClient.new(DataGlueSettings::master_ref['host'], DataGlueSettings::master_ref['port'], :pool_size => 1)
    db = @mongo_client.db(DataGlueSettings::master_ref['db'])
    auth = nil
    if DataGlueSettings::master_ref['user'] and DataGlueSettings::master_ref['user'] != '' && DataGlueSettings::master_ref['pass']
      auth = db.authenticate(DataGlueSettings::master_ref['user'], DataGlueSettings::master_ref['pass'])
      p "Authentication to mongo returned: #{auth}"
    end
    @coll_refs = db[DataGlueSettings::master_ref['collection']]
    @coll_cache = db[DataGlueSettings::master_ref['cache']]
  end

  #def self.mongo_client
  #  @mongo_client
  #end
  #def self.included(base)
  #
  #  @mongo_client
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

  def self.ref_upsert(doc)
    # First sanitize the doc from angular to remove any $$hashKey elements
    doc['dbReferences'].each do |k, v|
      v['fields'].each {|f| f.except!('$$hashKey')}
    end

    saved_or_updated_id = nil
    # If no _id this is a brand new document
    if doc['_id'].nil? or doc['_id'] == ''
      saved_or_updated_id = @coll_refs.insert(doc)
      p "New cached document inserted with _id: #{saved_or_updated_id.to_s}"
    else
      #saved_or_updated_id = self.get_mongo_id(doc['_id'])
      saved_or_updated_id = BSON::ObjectId(doc['_id'])
      doc['_id'] = saved_or_updated_id
      p "Existing cached document received with _id: #{doc['_id'].to_s}"
      ap doc
      @coll_refs.update({:_id => doc['_id']}, doc, opts = {:upsert => true})
    end
    saved_or_updated_id.to_s
  end

  def self.ref_get(_id)
    #_id = self.get_mongo_id(_id)
    ap _id
    doc = @coll_refs.find_one({:_id => BSON::ObjectId(_id)})
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
    client = Mysql2::Client.new(:host => host, :username => user, :password => pass, :database => db, :encoding=>'utf8')
    client.query(sql)
  end

  def self.query(ref, sql, single=false)
    ap sql
    type = DataGlueSettings::mysql_refs[ref]['type']
    if type == 'mysql'
      return self.mysql_query(ref, sql, single)
    end
  end

  def self.query_dataset(doc, opts={})
    data = {}
    tmp = {}
    threads = []
    doc['dbReferences'].each do |key, dbReference|
      threads << Thread.new {
        # Db reference is a key => value (hash)
        data[key] = self.query_dynamic(dbReference['connection'], dbReference['schema'], dbReference['table'], dbReference['fields'])
        ap "Data key: #{key} length: #{data[key].length}"
      }
    end

    # Join each of the threads that fetched the data
    threads.each {|t| t.join()}

    # TODO just do all cross db joins now in Ruby, not feasible to do this in javascript due to the potential amount
    # Of data being gzipped.  Event say 1-2 megs of gzipped content which is 9 megs uncompressed results in the
    # Browser malfunctioning on a quad i7 laptop with 8g ram.
    doc['dbReferences'].each do |dbReference, value|
      tmp[dbReference] = {
          :rawValues => nil
      }

      # Make sure the d3 key is in the hash
      if tmp[dbReference].has_key?(:d3).nil?
        tmp[dbReference][:d3] = {}
      end

        value['fields'].each do |field|

          # Make sure the field is in the hash
          if tmp[dbReference][:field].nil?
            tmp[dbReference][:field] = field
          end

          ################################################
          # Grouping by must always come first
          ################################################
          if field['groupBy'] and field['groupBy'] != ''
            groupedRows = {}
          end
      end
    end

    ap tmp
    return data
  end

  def self.build_sql_query(ref, schema, table, fields)
    sql = "SELECT #{fields.select {|x| !x['excludeField']}.map {|x| x['COLUMN_NAME']}.join(',')} FROM `#{schema}`.`#{table}`"

    # Iterate over each of the fields, see if there are any WHERE clauses set, if so, restrict by that were
    conditions = []
    fields.each do |field|
      #ap "conditioning on field #{field}"
      if field.key?('beginDate')
        conditions << " #{field['COLUMN_NAME']} >= TIMESTAMP('#{field['beginDate']}')"
      end
      if field.key?('endDate')
        conditions << " #{field['COLUMN_NAME']} < TIMESTAMP('#{field['endDate']}')"
      end
    end

    if conditions.length > 0
      sql << ' WHERE ' << conditions.join(' AND ')
    end

    sql
  end

  def self.query_dynamic(ref, schema, table, fields)
    type = DataGlueSettings::mysql_refs[ref]['type']
    if type == 'mysql'

      # The fields array should have the type of each field unless we are dealing with NoSQL then it should be provided by the UI or yaml mapping?

      # TODO I will need a more intelligent map to map based on column name

      # Let's first deal with the most basic use of grabbing the data from the reference and sending it back up
      sql = self.build_sql_query(ref, schema, table, fields)

      # Let's see if the sql query already exists with cached results
      potential_cache = @coll_cache.find_one({:sql => sql})
      # Potential cache means an entry found in cache, but still need to verify the sql matches the _id since it may have changed
      if potential_cache
        if potential_cache['sql'] == sql && potential_cache['data']
          logger.debug "Cache hit for: #{ref}, schema: #{schema}, table: #{table}, sql: #{sql}"
          # Re-inflate the json data and return
          return JSON.parse(Snappy.inflate(potential_cache['data'].to_s))
        end
      else
        # Otherwise no cache hit, go ahead and query like normal and return the cursor
        return self.mysql_query(ref, sql)

        # No longer caching this here, it will be cached up the chain once the data is converted to d3
        #logger.debug "Cache miss for: #{ref}, schema: #{schema}, table: #{table}, sql: #{sql}"
        #results = self.mysql_query(ref, sql).to_a
        #if results
        #  @coll_cache.update({:sql => sql}, {'$set' => {:data => BSON::Binary.new(Snappy.deflate(results.to_json)), :last_touched => Time.now.utc}}, opts={:upsert => true})
        #  return results
        #end
        #return []
      end
    end
  end

end
