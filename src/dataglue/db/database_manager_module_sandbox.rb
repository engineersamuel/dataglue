require 'mongo'
require 'awesome_print'
require_relative 'database_manager_module'

class DatabaseManagerSandbox

  include DatabaseManagerModule

  def test
    _id = '52277447f95fb65818000001'
    doc = DatabaseManagerModule::ref_get(_id)
    ap doc
    #results = DatabaseManagerModule::query_dataset(doc)
    #ap results
  end

  def test_mongo_client
    _id = '52277447f95fb65818000001'
    p "db: #{DataGlueSettings::master_ref['db']}"
    p "collection: #{DataGlueSettings::master_ref['collection']}"
    mongo_client = MongoClient.new(DataGlueSettings::master_ref['host'], DataGlueSettings::master_ref['port'], :pool_size => 1)
    db = mongo_client[DataGlueSettings::master_ref['db']]
    coll = db[DataGlueSettings::master_ref['collection']]
    doc = coll.find_one({:_id => BSON::ObjectId(_id)})
    ap doc
  end

  def test_query_dataset
    _id = '52277447f95fb65818000001'
    doc = DatabaseManagerModule::ref_get(_id)
    results = DatabaseManagerModule::query_dataset(doc)
    #ap results
  end
end

if __FILE__ == $0
  z = DatabaseManagerSandbox.new
  #z.test
  #z.test_mongo_client
  z.test_query_dataset
end

